import 'dart:async';
import 'package:core_flutter/common/k.dart';
import 'package:core_flutter/network/network_auth_config.dart';
import 'package:core_flutter/network/network_auth_handle.dart';
import 'package:core_flutter/network/network_dev_logger.dart';
import 'package:core_flutter/network/network_exception.dart';
import 'package:core_flutter/network/network_service_error_handler.dart';
import 'package:core_flutter/network/network_service_implement.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class NetworkService with NetworkServiceErrorHandler implements NetworkServiceImplement {
  final Dio _dio;
  final String baseUrl;
  final Duration setupDurationTimeOut;
  final bool showTokenValue;
  final NetworkAuthConfig? networkAuthConfig;

  NetworkService({
    required this.baseUrl,
    this.setupDurationTimeOut = const Duration(seconds: 60),
    this.showTokenValue = true,
    this.networkAuthConfig,
    /// Optional list of [additionalInterceptors] to inject into the Dio client.
    ///
    /// You can use this to add custom logic (logging, analytics) or to completely
    /// replace the default [authConfig] if you prefer to manage authentication independently.
    ///
    /// **Important Note:** The `withToken` flag in HTTP methods still functions
    /// as expected. You can easily access its value inside your custom interceptors
    /// via `options.extra['withToken']`.
    List<Interceptor>? additionalInterceptors,
  }) : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: setupDurationTimeOut,
          receiveTimeout: setupDurationTimeOut,
          sendTimeout: setupDurationTimeOut,
        )) {
    if (networkAuthConfig != null) {
      _dio.interceptors.add(NetworkAuthHandle(
        _dio,
        networkAuthConfig!,
        setupDurationTimeOut,
        showTokenValue,
      ));
    }
    if (additionalInterceptors != null) {
      _dio.interceptors.addAll(additionalInterceptors);
    }
    if (kDebugMode) {
      _dio.interceptors.add(NetworkDevLogger(showTokenValue: showTokenValue));
    }
  }

  @override
  Future<Result<T>> get<T>({
    String endpoint = "",
    Map<String, dynamic>? query,
    T Function(dynamic)? fromJson,
    bool withToken = false,
  }) {
    return _request<T>(
      endpoint: endpoint,
      method: K.getMethod,
      query: query,
      fromJson: fromJson,
      withToken: withToken,
    );
  }

  @override
  Future<Result<T>> post<T>({
    String endpoint = "",
    Object? data,
    T Function(dynamic)? fromJson,
    bool withToken = false,
  }) {
    return _request<T>(
      endpoint: endpoint,
      method: K.postMethod,
      data: data,
      fromJson: fromJson,
      withToken: withToken,
    );
  }

  @override
  Future<Result<T>> put<T>({
    String endpoint = "",
    Object? data,
    T Function(dynamic)? fromJson,
    bool withToken = false,
  }) {
    return _request<T>(
      endpoint: endpoint,
      method: K.putMethod,
      data: data,
      fromJson: fromJson,
      withToken: withToken,
    );
  }

  @override
  Future<Result<T>> patch<T>({
    String endpoint = "",
    Object? data,
    T Function(dynamic)? fromJson,
    bool withToken = false,
  }) {
    return _request<T>(
      endpoint: endpoint,
      method: K.patchMethod,
      data: data,
      fromJson: fromJson,
      withToken: withToken,
    );
  }

  @override
  Future<Result<T>> delete<T>({
    String endpoint = "",
    Map<String, dynamic>? query,
    Object? data,
    T Function(dynamic)? fromJson,
    bool withToken = false,
  }) {
    return _request<T>(
      endpoint: endpoint,
      method: K.deleteMethod,
      query: query,
      data: data,
      fromJson: fromJson,
      withToken: withToken,
    );
  }

  Future<Result<T>> _request<T>({
    String endpoint = "",
    required String method,
    Object? data,
    Map<String, dynamic>? query,
    bool withToken = false,
    T Function(dynamic)? fromJson,
  }) async {
    return handleRequest<T>(
      () async {
        return _dio.request(
          endpoint,
          data: data,
          queryParameters: query,
          options: Options(
            method: method,
            extra: { 'withToken': withToken },
          ),
        ).timeout(setupDurationTimeOut);
      },
      fromJson,
    );
  }
}