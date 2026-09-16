import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'connectivity_provider.g.dart';

@Riverpod(keepAlive: true)
Stream<List<ConnectivityResult>> connectivityStream(Ref ref) {
  return Connectivity().onConnectivityChanged;
}

@Riverpod(keepAlive: true)
class ConnectivityMessage extends _$ConnectivityMessage {
  @override
  String? build() {
    return null;
  }

  void setError(String? message) {
    state = message;
  }
}
