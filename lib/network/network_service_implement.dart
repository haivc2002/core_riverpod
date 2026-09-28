import 'package:core_riverpod/network/network_exception.dart';

abstract class NetworkServiceImplement {
  Future<T> get<T>({
    String endpoint = "",
    Map<String, dynamic>? query,
    T Function(dynamic)? fromJson,
    bool withToken = false,
  }) {
    throw UnimplementedError('get method not implemented');
  }

  Future<T> post<T>({
    String endpoint = "",
    Object? data,
    T Function(dynamic)? fromJson,
    bool withToken = false,
  }) {
    throw UnimplementedError('post method not implemented');
  }

  Future<T> put<T>({
    String endpoint = "",
    Object? data,
    T Function(dynamic)? fromJson,
    bool withToken = false,
  }) {
    throw UnimplementedError('put method not implemented');
  }

  Future<T> patch<T>({
    String endpoint = "",
    Object? data,
    T Function(dynamic)? fromJson,
    bool withToken = false,
  }) {
    throw UnimplementedError('patch method not implemented');
  }

  Future<T> delete<T>({
    String endpoint = "",
    Map<String, dynamic>? query,
    Object? data,
    T Function(dynamic)? fromJson,
    bool withToken = false,
  }) {
    throw UnimplementedError('delete method not implemented');
  }
}