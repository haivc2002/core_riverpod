import 'package:core_riverpod/common/core_utils.dart';
import 'package:core_riverpod/common/global_entity.dart';
import 'package:core_riverpod/localization/core_locale_provider.dart';
import 'package:flutter/material.dart';
import 'package:core_riverpod/network/network_exception.dart';
import 'package:core_riverpod/connectivity/connectivity_provider.dart';
import 'package:core_riverpod/localization/core_messages.dart';
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:core_riverpod/common/core_scroll_controller.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';



mixin BaseNotifier<T> {
  AsyncValue<T> get state;
  set state(AsyncValue<T> value);

  void setScreenLoading() {
    // ignore: invalid_use_of_internal_member
    state = AsyncLoading<T>().copyWithPrevious(state);
  }
  bool _isLoadMore            = false;
  bool _isMoreEnable          = true;
  bool withScrollController   = false;

  late CoreScrollController scrollController;

  bool get isMoreEnable => _isMoreEnable;
  set isMoreEnable(bool value) {
    _isMoreEnable = value;
    if (withScrollController) {
      scrollController.isMoreEnable = value;
    }
  }
  dynamic get _ref => (this as dynamic).ref;

  CoreMessages get coreMessages {
    final context = coreNavigatorKey.currentContext;
    if (context != null) {
      return CoreMessages.of(context);
    }
    throw Exception("Cannot access CoreMessages without a context!");
  }

  set setEnableScrollController(bool value) => withScrollController = value;



  Future<R> executeWithAutomaticConnectionRecovery<R>(
      Future<R> Function() apiCall, {
      int maxRetries = 3,
  }) async {
    int retryCount = 0;
    while (true) {
      if (_isScreenStateDisposed) throw Exception("Thao tác bị hủy vì màn hình đã đóng.");
      
      try {
        return await apiCall();
      } on Failure catch (e) {
        if (e.code == Failure.isNotConnect) {
          if (retryCount >= maxRetries) {
            _ref.read(connectivityMessageProvider.notifier).setError(null);
            rethrow;
          }
          retryCount++;
          
          final errorMessage = coreMessages.networkDisconnected;
          _ref.read(connectivityMessageProvider.notifier).setError(errorMessage);
          await _waitForConnection();
          _ref.read(connectivityMessageProvider.notifier).setError(null);
          continue;
        }
        rethrow;
      }
    }
  }

  Future<void> _waitForConnection() async {
    final currentResults = await Connectivity().checkConnectivity();
    if (currentResults.isNotEmpty && !currentResults.contains(ConnectivityResult.none)) {
      await Future.delayed(const Duration(seconds: 2));
      return;
    }
    final completer = Completer<void>();
    final sub = _ref.listen(connectivityStreamProvider, (prev, next) {
      if (next case AsyncData(:final value)) {
        if (value is List<ConnectivityResult> &&
            value.isNotEmpty &&
            !value.contains(ConnectivityResult.none)) {
          if (!completer.isCompleted) completer.complete();
        }
      }
    });
    await completer.future;
    sub.close();
  }

  void onInitStateBaseNotifier() {
    coreLog("CREATE $runtimeType");
    _isLoadMore = false;
    _isMoreEnable = true;
    if (withScrollController) {
      scrollController = CoreScrollController();
      scrollController.addListener(_scrollListener);
    }
  }

  void _scrollListener() {
    if (scrollController.offset >= scrollController.position.maxScrollExtent &&
        !scrollController.position.outOfRange) {
      if (!_isLoadMore && isMoreEnable) {
        _isLoadMore = true;
        scrollController.isLoadMore = true;
        onLoadMore();
      }
    }
  }

  void registerGlobalAction(String key, dynamic Function(dynamic data) action) {
    GlobalAction.register(key, action);
    _ref.onDispose(() => GlobalAction.unregister(key));
  }

  dynamic dispatchGlobalAction(String key, [dynamic data]) {
    return GlobalAction.dispatch(key, data);
  }

  void updateGlobalValue(String key, dynamic value) {
    _ref.read(globalStateProvider(key).notifier).updateState(value);
  }

  dynamic readGlobalValue(String key) {
    return _ref.read(globalStateProvider(key));
  }

  /// Ex: @override
  ///   void onLoadMore() {
  ///     _page ++;
  ///     onFetchData(page: _page);
  ///     super.onLoadMore();
  ///   }
  void onLoadMore() {
    coreLog("ENABLE LOAD MORE");
    _isLoadMore = false;
    if (withScrollController) scrollController.isLoadMore = false;
  }

  /// Ex: @override
  ///   void onRefresh() {
  ///     super.onLoadMore();
  ///     onFetchData();
  ///   }
  ///   #####################
  ///   Gọi hàm [onFetchData] sau super.onLoadMore() để thực hiện [_isLoadMore] & [isMoreEnable] trước
  Future<void> onRefresh() async {
    _isLoadMore = false;
    isMoreEnable = true;
    if (withScrollController) scrollController.isLoadMore = false;
    coreLog("ENABLE REFRESH");
  }

  void onDispose() {
    coreLog("CLOSE $runtimeType");
    if (withScrollController) scrollController.dispose();
  }

  void onChangeLocale(Locale locale) {
    _ref.read(coreLocaleProvider.notifier).setLocale(locale);
  }
}