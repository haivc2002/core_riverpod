import 'dart:async';
import 'package:core_riverpod/core_riverpod.dart';
import 'package:core_riverpod/network/network_dev_logger.dart';

class DebugNetworkNotifier extends Notifier<List<NetworkErrorInfo>> {
  static DebugNetworkNotifier? instance;
  StreamSubscription<NetworkErrorInfo>? _sub;

  @override
  List<NetworkErrorInfo> build() {
    instance = this;
    _sub?.cancel();
    _sub = NetworkDevLogger.onNetworkError.stream.listen((error) {
      state = [error, ...state.take(49)];
    });
    ref.onDispose(() {
      _sub?.cancel();
      _sub = null;
      if (instance == this) instance = null;
    });
    return List<NetworkErrorInfo>.from(NetworkDevLogger.errorHistory);
  }

  void addError(NetworkErrorInfo error) {
    state = [error, ...state.take(49)];
  }

  void clear() {
    NetworkDevLogger.clearErrors();
    state = [];
  }
}

final debugNetworkProvider = NotifierProvider<DebugNetworkNotifier, List<NetworkErrorInfo>>(
  DebugNetworkNotifier.new,
);
