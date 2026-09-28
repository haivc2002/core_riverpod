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

  Future<Result<T>> handleRequest<T>(
      Future<Response> Function() request, [
      T Function(dynamic)? fromJson,
      ]) async {
    try {
      final response = await request();
      return _handleResponse(response, fromJson);
    } on DioException catch (e) {
      if (e.error is SessionExpiredException) throw e.error!;
      return switch (e.type) {
        DioExceptionType.connectionError => Failure(
          Result.isNotConnect,
          _messages.networkDisconnected,
        ),
        _ => Failure(
          e.response?.statusCode ?? Result.isDueServer,
          _messages.noServerResponse,
        ),
      };
    } on TimeoutException {
      return Failure(Result.isTimeOut, _messages.networkTimeout);
    } catch (e, stackTrace) {
      if (e is SessionExpiredException) rethrow;
      coreLog(e.toString(), stackTrace: stackTrace, error: e, name: K.nameNetwork);
      return Failure(Result.isError, _messages.serverBusy);
    }
  }

  Result<T> _handleResponse<T>(
      Response response,
      T Function(dynamic)? fromJson,
      ) => switch (response.statusCode) {
    200 when fromJson != null => Success(fromJson(response.data)),
    200 => Success(response.data as T),
    _   => Failure(
      response.statusCode ?? Result.isHttp,
      _messages.serverError,
    ),
  };
}
