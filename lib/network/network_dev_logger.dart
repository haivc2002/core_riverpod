import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:dio/dio.dart';

const _timeStampKey = '_pdl_timeStamp_';

class NetworkErrorInfo {
  final String id;
  final String method;
  final String url;
  final String endpoint;
  final int? statusCode;
  final String? statusMessage;
  final String errorType;
  final String message;
  final dynamic requestData;
  final Map<String, dynamic>? queryParameters;
  final dynamic responseData;
  final DateTime timestamp;
  final int durationMs;

  NetworkErrorInfo({
    required this.id,
    required this.method,
    required this.url,
    required this.endpoint,
    this.statusCode,
    this.statusMessage,
    required this.errorType,
    required this.message,
    this.requestData,
    this.queryParameters,
    this.responseData,
    required this.timestamp,
    required this.durationMs,
  });
}

/// A pretty logger for Dio
/// it will print request/response info with a pretty format
/// and also can filter the request/response by [RequestOptions]
class NetworkDevLogger extends Interceptor {
  /// Print request [Options]
  final bool request;

  /// Print request header [Options.headers]
  final bool requestHeader;

  /// Print request data [Options.dataBook]
  final bool requestBody;

  /// Print [Response.data]
  final bool responseBody;

  /// Print [Response.headers]
  final bool responseHeader;

  /// Print error message
  final bool error;

  /// InitialTab count to logPrint json response
  static const int kInitialTab = 1;

  /// 1 tab length
  static const String tabStep = '    ';

  /// Print compact json response
  final bool compact;

  /// Width size per logPrint
  final int maxWidth;

  /// Size in which the Uint8List will be split
  static const int chunkSize = 20;

  /// Log printer; defaults logPrint log to console.
  /// In flutter, you'd better use debugPrint.
  /// you can also write log in a file.
  final void Function(Object object) logPrint;

  /// Filter request/response by [RequestOptions]
  final bool Function(RequestOptions options, FilterArgs args)? filter;

  /// Enable logPrint
  final bool enabled;

  /// Print Token Value
  final bool showTokenValue;

  /// Default constructor
  NetworkDevLogger({
    this.request = true,
    this.requestHeader = false,
    this.requestBody = false,
    this.responseHeader = false,
    this.responseBody = true,
    this.error = true,
    this.maxWidth = 90,
    this.compact = true,
    this.logPrint = print,
    this.filter,
    this.enabled = true,
    this.showTokenValue = true,
  });

  static final List<NetworkErrorInfo> errorHistory = [];
  static final StreamController<NetworkErrorInfo> onNetworkError = StreamController<NetworkErrorInfo>.broadcast();

  static void addError(NetworkErrorInfo error) {
    errorHistory.insert(0, error);
    if (errorHistory.length > 50) {
      errorHistory.removeLast();
    }
    onNetworkError.add(error);
  }

  static void clearErrors() {
    errorHistory.clear();
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final extra = Map.of(options.extra);
    options.extra[_timeStampKey] = DateTime.timestamp().millisecondsSinceEpoch;

    if (!enabled ||
        (filter != null &&
            !filter!(options, FilterArgs(false, options.data)))) {
      handler.next(options);
      return;
    }

    if (request) {
      logPrint('');
      logPrint('╔╣ Request ║ ${options.method} ');
      logPrint('║  ${options.uri.toString()}');
      
      // Print Token if available
      final token = options.headers['Authorization'];
      if (token != null && showTokenValue) {
        final tokenStr = token.toString();
        final prefix = '║  Token: ';
        final maxLen = maxWidth - prefix.length;
        if (tokenStr.length <= maxLen) {
          logPrint('$prefix$tokenStr');
        } else {
          logPrint('$prefix${tokenStr.substring(0, maxLen)}');
          int offset = maxLen;
          while (offset < tokenStr.length) {
            final chunkLen = maxWidth - 10;
            final chunk = tokenStr.substring(offset, math.min(offset + chunkLen, tokenStr.length));
            logPrint('║         $chunk');
            offset += chunkLen;
          }
        }
      }

      String formatRequestBody(dynamic data) {
        if (data is FormData) {
          final buffer = StringBuffer();
          buffer.writeln('FormData:');
          for (final field in data.fields) {
            buffer.writeln('║    ${field.key}: ${field.value}');
          }
          for (final file in data.files) {
            final fileData = file.value;
            buffer.writeln('║    ${file.key}: filename=${fileData.filename}, contentType=${fileData.contentType}');
          }
          return buffer.toString().trimRight();
        } else {
          return data.toString();
        }
      }
      
      if (options.data != null) {
        final bodyStr = formatRequestBody(options.data);
        final prefix = '║  Body: ';
        final maxLen = maxWidth - prefix.length;
        if (bodyStr.length <= maxLen) {
          logPrint('$prefix$bodyStr');
        } else {
          logPrint('$prefix${bodyStr.substring(0, maxLen)}');
          int offset = maxLen;
          while (offset < bodyStr.length) {
            final chunkLen = maxWidth - 10;
            final chunk = bodyStr.substring(offset, math.min(offset + chunkLen, bodyStr.length));
            logPrint('║         $chunk');
            offset += chunkLen;
          }
        }
      }
      _printLine('╚');
    }

    if (requestHeader) {
      _printMapAsTable(options.queryParameters, header: 'Query Parameters');
      final requestHeaders = <String, dynamic>{};
      requestHeaders.addAll(options.headers);
      if (options.contentType != null) {
        requestHeaders['contentType'] = options.contentType?.toString();
      }
      requestHeaders['responseType'] = options.responseType.toString();
      requestHeaders['followRedirects'] = options.followRedirects;
      if (options.connectTimeout != null) {
        requestHeaders['connectTimeout'] = options.connectTimeout?.toString();
      }
      if (options.receiveTimeout != null) {
        requestHeaders['receiveTimeout'] = options.receiveTimeout?.toString();
      }
      _printMapAsTable(requestHeaders, header: 'Headers');
      _printMapAsTable(extra, header: 'Extras');
    }

    if (requestBody && options.method != 'GET') {
      final dynamic data = options.data;
      if (data != null) {
        if (data is Map) _printMapAsTable(options.data as Map?, header: 'Body (Pretty)');
        else if (data is FormData) {
          final formDataMap = <String, dynamic>{}
            ..addEntries(data.fields)
            ..addEntries(data.files);
          _printMapAsTable(formDataMap, header: 'Form data | ${data.boundary}');
        }
      }
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final triggerTime = err.requestOptions.extra[_timeStampKey];
    int diff = 0;
    if (triggerTime is int) {
      diff = DateTime.timestamp().millisecondsSinceEpoch - triggerTime;
    }

    String type = "Unknown Error";
    if (err.response != null) {
      final status = err.response!.statusCode ?? 0;
      if (status >= 500) {
        type = "Server Error ($status)";
      } else if (status >= 400) {
        type = "Client Error ($status)";
      } else {
        type = "HTTP Error ($status)";
      }
    } else {
      switch (err.type) {
        case DioExceptionType.connectionTimeout:
          type = "Connection Timeout";
        case DioExceptionType.sendTimeout:
          type = "Send Timeout";
        case DioExceptionType.receiveTimeout:
          type = "Receive Timeout";
        case DioExceptionType.badCertificate:
          type = "Bad Certificate";
        case DioExceptionType.cancel:
          type = "Request Cancelled";
        case DioExceptionType.connectionError:
          type = "Connection Error / No Internet";
        default:
          type = "Network Exception";
      }
    }

    final errorInfo = NetworkErrorInfo(
      id: "${DateTime.now().microsecondsSinceEpoch}",
      method: err.requestOptions.method.toUpperCase(),
      url: err.requestOptions.uri.toString(),
      endpoint: err.requestOptions.path,
      statusCode: err.response?.statusCode,
      statusMessage: err.response?.statusMessage,
      errorType: type,
      message: err.message ?? err.toString(),
      requestData: err.requestOptions.data,
      queryParameters: err.requestOptions.queryParameters,
      responseData: err.response?.data,
      timestamp: DateTime.now(),
      durationMs: diff,
    );

    addError(errorInfo);


    if (!enabled ||
        (filter != null &&
            !filter!(
                err.requestOptions, FilterArgs(true, err.response?.data)))) {
      handler.next(err);
      return;
    }

    if (error) {
      if (err.type == DioExceptionType.badResponse) {
        final uri = err.response?.requestOptions.uri;
        int diff = 0;
        if (triggerTime is int) {
          diff = DateTime.timestamp().millisecondsSinceEpoch - triggerTime;
        }
        _printBoxed(
            header:
            'DioError ║ Status: ${err.response?.statusCode} ${err.response?.statusMessage} ║ Time: $diff ms',
            text: uri.toString());
        if (err.response != null && err.response?.data != null) {
          logPrint('╔ ${err.type.toString()}');
          _printResponse(err.response!);
        }
        _printLine('╚');
        logPrint('');
      } else {
        _printBoxed(header: 'DioError ║ ${err.type}', text: err.message);
      }
    }
    handler.next(err);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (!enabled ||
        (filter != null &&
            !filter!(
                response.requestOptions, FilterArgs(true, response.data)))) {
      handler.next(response);
      return;
    }

    final triggerTime = response.requestOptions.extra[_timeStampKey];

    int diff = 0;
    if (triggerTime is int) {
      diff = DateTime.timestamp().millisecondsSinceEpoch - triggerTime;
    }
    _printResponseHeader(response, diff);
    if (responseHeader) {
      final responseHeaders = <String, String>{};
      response.headers
          .forEach((k, list) => responseHeaders[k] = list.toString());
      _printMapAsTable(responseHeaders, header: 'Headers');
    }

    if (responseBody) {
      logPrint('╔ Data');
      logPrint('║');
      _printResponse(response);
      logPrint('║');
      _printLine('╚');
    }
    handler.next(response);
  }

  void _printBoxed({String? header, String? text}) {
    logPrint('');
    logPrint('╔╣ $header');
    logPrint('║  $text');
    _printLine('╚');
  }

  void _printResponse(Response response) {
    if (response.data != null) {
      if (response.data is Map) {
        _printPrettyMap(response.data as Map);
      } else if (response.data is Uint8List) {
        logPrint('║${_indent()}[');
        _printUint8List(response.data as Uint8List);
        logPrint('║${_indent()}]');
      } else if (response.data is List) {
        logPrint('║${_indent()}[');
        _printList(response.data as List);
        logPrint('║${_indent()}]');
      } else {
        _printBlock(response.data.toString());
      }
    }
  }

  void _printResponseHeader(Response response, int responseTime) {
    final uri = response.requestOptions.uri;
    final method = response.requestOptions.method;
    _printBoxed(
        header:
        'Response ║ $method ║ Status: ${response.statusCode} ${response.statusMessage}  ║ Time: $responseTime ms',
        text: uri.toString());
  }

  void _printRequestHeader(RequestOptions options) {
    final uri = options.uri;
    final method = options.method;
    _printBoxed(header: 'Request ║ $method ', text: uri.toString());
  }

  void _printLine([String pre = '', String suf = '╝']) =>
      logPrint('$pre${'═' * maxWidth}$suf');

  void _printKV(String? key, Object? v) {
    final pre = '╟ $key: ';
    final msg = v.toString();

    if (pre.length + msg.length > maxWidth) {
      logPrint(pre);
      _printBlock(msg);
    } else {
      logPrint('$pre$msg');
    }
  }

  void _printBlock(String msg) {
    final lines = (msg.length / maxWidth).ceil();
    for (var i = 0; i < lines; ++i) {
      logPrint((i >= 0 ? '║ ' : '') +
          msg.substring(i * maxWidth,
              math.min<int>(i * maxWidth + maxWidth, msg.length)));
    }
  }

  String _indent([int tabCount = kInitialTab]) => tabStep * tabCount;

  void _printPrettyMap(
      Map data, {
        int initialTab = kInitialTab,
        bool isListItem = false,
        bool isLast = false,
      }) {
    var tabs = initialTab;
    final isRoot = tabs == kInitialTab;
    final initialIndent = _indent(tabs);
    tabs++;

    if (isRoot || isListItem) logPrint('║$initialIndent{');

    for (var index = 0; index < data.length; index++) {
      final isLast = index == data.length - 1;
      final key = '"${data.keys.elementAt(index)}"';
      dynamic value = data[data.keys.elementAt(index)];
      if (value is String) {
        value = '"${value.toString().replaceAll(RegExp(r'([\r\n])+'), " ")}"';
      }
      if (value is Map) {
        if (compact && _canFlattenMap(value)) {
          logPrint('║${_indent(tabs)} $key: $value${!isLast ? ',' : ''}');
        } else {
          logPrint('║${_indent(tabs)} $key: {');
          _printPrettyMap(value, initialTab: tabs);
        }
      } else if (value is List) {
        if (compact && _canFlattenList(value)) {
          logPrint('║${_indent(tabs)} $key: ${value.toString()}');
        } else {
          logPrint('║${_indent(tabs)} $key: [');
          _printList(value, tabs: tabs);
          logPrint('║${_indent(tabs)} ]${isLast ? '' : ','}');
        }
      } else {
        final msg = value.toString().replaceAll('\n', '');
        final indent = _indent(tabs);
        final linWidth = maxWidth - indent.length;
        if (msg.length + indent.length > linWidth) {
          final lines = (msg.length / linWidth).ceil();
          for (var i = 0; i < lines; ++i) {
            final multilineKey = i == 0 ? "$key:" : "";
            logPrint(
                '║${_indent(tabs)} $multilineKey ${msg.substring(i * linWidth, math.min<int>(i * linWidth + linWidth, msg.length))}');
          }
        } else {
          logPrint('║${_indent(tabs)} $key: $msg${!isLast ? ',' : ''}');
        }
      }
    }

    logPrint('║$initialIndent}${isListItem && !isLast ? ',' : ''}');
  }

  void _printList(List list, {int tabs = kInitialTab}) {
    for (var i = 0; i < list.length; i++) {
      final element = list[i];
      final isLast = i == list.length - 1;
      if (element is Map) {
        if (compact && _canFlattenMap(element)) {
          logPrint('║${_indent(tabs)}  $element${!isLast ? ',' : ''}');
        } else {
          _printPrettyMap(
            element,
            initialTab: tabs + 1,
            isListItem: true,
            isLast: isLast,
          );
        }
      } else {
        logPrint('║${_indent(tabs + 2)} $element${isLast ? '' : ','}');
      }
    }
  }

  void _printUint8List(Uint8List list, {int tabs = kInitialTab}) {
    var chunks = [];
    for (var i = 0; i < list.length; i += chunkSize) {
      chunks.add(
        list.sublist(
            i, i + chunkSize > list.length ? list.length : i + chunkSize),
      );
    }
    for (var element in chunks) {
      logPrint('║${_indent(tabs)} ${element.join(", ")}');
    }
  }

  bool _canFlattenMap(Map map) {
    return map.values
        .where((dynamic val) => val is Map || val is List)
        .isEmpty &&
        map.toString().length < maxWidth;
  }

  bool _canFlattenList(List list) {
    return list.length < 10 && list.toString().length < maxWidth;
  }

  void _printMapAsTable(Map? map, {String? header}) {
    if (map == null || map.isEmpty) return;
    logPrint('╔ $header ');
    for (final entry in map.entries) {
      _printKV(entry.key.toString(), entry.value);
    }
    _printLine('╚');
  }
}

/// Filter arguments
class FilterArgs {
  /// If the filter is for a request or response
  final bool isResponse;

  /// if the [isResponse] is false, the data is the [RequestOptions.data]
  /// if the [isResponse] is true, the data is the [Response.data]
  final dynamic data;

  /// Returns true if the data is a string
  bool get hasStringData => data is String;

  /// Returns true if the data is a map
  bool get hasMapData => data is Map;

  /// Returns true if the data is a list
  bool get hasListData => data is List;

  /// Returns true if the data is a Uint8List
  bool get hasUint8ListData => data is Uint8List;

  /// Returns true if the data is a json data
  bool get hasJsonData => hasMapData || hasListData;

  /// Default constructor
  const FilterArgs(this.isResponse, this.data);
}
