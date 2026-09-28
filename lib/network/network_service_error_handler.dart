import 'dart:async';
import 'package:core_riverpod/common/k.dart';
import 'package:core_riverpod/common/core_utils.dart';
import 'package:core_riverpod/network/network_exception.dart';
import 'package:dio/dio.dart';

import 'package:core_riverpod/localization/core_messages.dart';

class _EmergencyMessages extends NetworkExceptionMessage {
  @override String get networkDisconnected  => 'No network connection';
  @override String get networkTimeout       => 'Connection timed out';
  @override String get unknownError         => 'An error occurred';
  @override String get noServerResponse     => 'No response from the server';
  @override String get serverBusy           => 'System is busy';
  @override String get serverError          => 'A server error occurred';
}

mixin NetworkServiceErrorHandler {

  NetworkExceptionMessage get _messages {
    final context = coreNavigatorKey.currentContext;
    if (context != null) return CoreMessages.of(context);
    return _EmergencyMessages();
  }

  Future<T> handleRequest<T>(
      Future<Response> Function() request, [
      T Function(dynamic)? fromJson,
      ]) async {
    try {
      final response = await request();
      return await _handleResponse(response, fromJson);
    } on DioException catch (e) {
      if (e.error is SessionExpiredException) throw e.error!;
      throw switch (e.type) {
        DioExceptionType.connectionError => Failure(
          Failure.isNotConnect,
          _messages.networkDisconnected,
        ),
        _ => Failure(
          e.response?.statusCode ?? Failure.isDueServer,
          _messages.noServerResponse,
        ),
      };
    } on TimeoutException {
      throw Failure(Failure.isTimeOut, _messages.networkTimeout);
    } catch (e, stackTrace) {
      if (e is SessionExpiredException) rethrow;
      coreLog(e.toString(), stackTrace: stackTrace, error: e, name: K.nameNetwork);
      throw Failure(Failure.isError, _messages.serverBusy);
    }
  }

  T _handleResponse<T>(
      Response response,
      T Function(dynamic)? fromJson,
      ) => switch (response.statusCode) {
    200 when fromJson != null => fromJson(response.data),
    200 => response.data as T,
    _   => throw Failure(
      response.statusCode ?? Failure.isHttp,
      _messages.serverError,
    ),
  };
}
