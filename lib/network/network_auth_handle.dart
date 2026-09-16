import 'package:core_flutter/common/core_utils.dart';
import 'package:core_flutter/common/k.dart';
import 'package:core_flutter/network/network_auth_config.dart';
import 'package:core_flutter/network/network_dev_logger.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:core_flutter/network/network_exception.dart';

class NetworkAuthHandle extends QueuedInterceptor {
  final Dio _dio;
  final NetworkAuthConfig _authConfig;
  final Duration timeOut;
  final bool showTokenValue;

  bool _isError = false;

  NetworkAuthHandle(
    this._dio,
    this._authConfig,
    this.timeOut,
    this.showTokenValue,
  );

  DateTime _parseDate(String dateStr) {
    try {
      final parts = dateStr.trim().split(' ');
      if (parts.length != 2) throw const FormatException();
      final dateParts = parts[0].split('/');
      final timeParts = parts[1].split(':');
      if (dateParts.length != 3 || timeParts.length != 2) throw const FormatException();
      return DateTime(
        int.parse(dateParts[2]), // yyyy
        int.parse(dateParts[1]), // MM
        int.parse(dateParts[0]), // dd
        int.parse(timeParts[0]), // HH
        int.parse(timeParts[1]), // mm
      );
    } catch (e) {
      throw FormatException("Invalid token time format 'dd/MM/yyyy HH:mm': $dateStr");
    }
  }

  void _triggerAuthErrorAndThrowIfNeeded() {
    _onAuthenticationError();
    if (_authConfig.blockOnAuthenticationError) {
      throw SessionExpiredException();
    }
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    try {
      final withToken = options.extra['withToken'] == true;
      if (!withToken) return handler.next(options);

      // 1. Check refresh token expiration (if configured)
      if (_authConfig.refreshTokenExpiresAt != null) {
        final refreshExpireStr = await _authConfig.refreshTokenExpiresAt!();
        if (refreshExpireStr.isNotEmpty) {
          final refreshExpireDate = _parseDate(refreshExpireStr);
          if (DateTime.now().isAfter(refreshExpireDate)) {
            _triggerAuthErrorAndThrowIfNeeded();
            return handler.next(options);
          }
        }
      }

      // 2. Check access token expiration (if configured)
      if (_authConfig.expirationAt != null) {
        final expireStr = await _authConfig.expirationAt!();
        if (expireStr.isNotEmpty) {
          final expireDate = _parseDate(expireStr);
          if (DateTime.now().isAfter(expireDate)) {
            // Expired -> Proactively refresh before calling the API
            try {
              if (_authConfig.endpoint != null) {
                await _onRefreshToken();
              } else {
                _triggerAuthErrorAndThrowIfNeeded();
                return handler.next(options);
              }
            } catch (e) {
              if (e case DioException(type: DioExceptionType.badResponse)) {
                _triggerAuthErrorAndThrowIfNeeded();
                return handler.next(options);
              }
              // If a regular network error occurs, allow the request to proceed and fail naturally
            }
          }
        }
      }

      // 3. Attach token and proceed
      if (_authConfig.accessToken != null) {
        final token = await _authConfig.accessToken!();
        if (token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
      }
    } catch (e) {
      if (e is FormatException || e is SessionExpiredException) rethrow;
      coreLog("Error during token preprocessing in request header: $e", name: K.nameNetwork);
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final withToken = err.requestOptions.extra['withToken'] == true;
    
    // Ignore if the API does not require a token or the error is not 401
    if (!withToken || err.response?.statusCode != 401) {
      return handler.next(err);
    }
    
    if (_isError) {
      if (_authConfig.blockOnAuthenticationError) throw SessionExpiredException();
      return handler.next(err);
    }
    
    if (_authConfig.endpoint == null) {
      _triggerAuthErrorAndThrowIfNeeded();
      return handler.next(err);
    }
    
    try {
      final originalToken = err.requestOptions.headers['Authorization']
          ?.toString()
          .replaceAll('Bearer ', '') ?? '';
      
      final currentToken = await _authConfig.accessToken?.call() ?? "";
      
      // Token has already been refreshed by another request -> Use it immediately
      if (originalToken != currentToken && currentToken.isNotEmpty) {
        return handler.resolve(await _retryRequest(err.requestOptions, currentToken));
      }
      
      // Token hasn't been refreshed -> Proceed with refresh
      await _onRefreshToken();
      final newToken = await _authConfig.accessToken?.call() ?? "";
      
      return handler.resolve(await _retryRequest(err.requestOptions, newToken));
      
    } catch (e) {
      // Catch bad response errors during refresh
      if (e case DioException(type: DioExceptionType.badResponse)) {
        _triggerAuthErrorAndThrowIfNeeded();
        return handler.next(err);
      }
      return handler.next(err);
    }
  }

  /// Helper function: Retries a failed request with the new token
  Future<Response<dynamic>> _retryRequest(RequestOptions options, String token) async {
    options.headers['Authorization'] = 'Bearer $token';
    final retryDio = Dio(BaseOptions(baseUrl: options.baseUrl));
    if (kDebugMode) {
      retryDio.interceptors.add(NetworkDevLogger(showTokenValue: showTokenValue));
    }
    return retryDio.fetch(options);
  }

  void _onAuthenticationError() {
    if (_isError) return;
    _isError = true;
    _authConfig.onAuthenticationError?.call();
  }

  Future<void> _onRefreshToken() async {
    final refreshDio = Dio(BaseOptions(baseUrl: _dio.options.baseUrl));
    if (kDebugMode) {
      refreshDio.interceptors.add(NetworkDevLogger(showTokenValue: showTokenValue));
    }
    
    final refreshToken = await _authConfig.refreshToken?.call() ?? "";
    final body = _authConfig.buildRequestBody?.call(refreshToken);
    final response = await refreshDio.post(_authConfig.endpoint!, data: body);
    
    if (response.data == null) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
      );
    }
    
    await _authConfig.onRefreshSuccess?.call(response.data);
  }
}