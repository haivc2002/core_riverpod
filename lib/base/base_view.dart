import "package:core_riverpod/debug/debug_notifier/debug_memory_notifier.dart";
import "package:core_riverpod/debug/debug_notifier/debug_panel_notifier.dart";
import "package:core_riverpod/localization/core_messages.dart";
import "package:core_riverpod/network/network_exception.dart";
import "package:core_riverpod/widget/widget_wait.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:core_riverpod/base/base_notifier.dart";
import "package:core_riverpod/connectivity/connectivity_provider.dart";
import "package:core_riverpod/common/global_entity.dart";
import "package:core_riverpod/debug/debug_core.dart";

abstract class BaseViewState<
  W extends StatefulHookConsumerWidget,
  N extends BaseNotifier<S>,
  S
> extends ConsumerState<W> {
  late AsyncValue<S> _asyncState;
  late N            _notifier;

  S             get state                       => _asyncState.requireValue;
  N             get viewModel                   => _notifier;
  bool          get enableListenBuilderLoading  => true;
  bool          get enableListenBuilderError    => true;

  AsyncValue<S> watchState(WidgetRef ref);

  N readNotifier(WidgetRef ref);

  T watchGlobalValue<T>(String key, {required T def}) {
    final value = ref.watch(globalStateProvider(key));
    if (value == null) return def;
    return value as T;
  }

  Widget zBuilder();
  
  void onInitView(BuildContext context) {}

  Widget buildLoadingView() => WidgetWait();

  Widget buildErrorView(covariant Failure error) {
    final messages = CoreMessages.of(context);
    final text = error.message.isNotEmpty ? error.message : messages.unknownError;
    return Text(text);
  }

  void _messageErrorNetwork(String? errorMsg) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.maybeOf(context);
      if (messenger == null) return;
      messenger.clearSnackBars();
      if (errorMsg == null) return;
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: ThemeData.light().colorScheme.inverseSurface,
          content: Text(
            errorMsg,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white),
          ),
          duration: const Duration(days: 365),
          behavior: SnackBarBehavior.fixed,
          dismissDirection: DismissDirection.none,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      ref.read(debugMemoryProvider);
      DebugMemoryNotifier.activeScreenName = runtimeType.toString();
    }
    _asyncState = watchState(ref);
    _notifier = readNotifier(ref);

    int routeId = 0;
    if (kDebugMode) {
      routeId = ModalRoute.of(context)?.hashCode ?? 0;
    }

    useEffect(() {
      final debugNotifier = kDebugMode ? ref.read(debugProvider.notifier) : null;
      final screenName = runtimeType.toString();
      if (kDebugMode) {
        Future.microtask(() => debugNotifier?.addScreen(screenName, routeId));
      }
      onInitView(context);
      DebugCore.show(context);
      return () {
        if (kDebugMode) {
          Future.microtask(() => debugNotifier?.removeScreen(screenName, routeId));
        }
      };
    }, const []);

    ref.listen(connectivityMessageProvider, (_, errorMsg) {
      _messageErrorNetwork(errorMsg);
    });

    final Widget originalView = _asyncState.hasValue ? zBuilder() : const SizedBox(); 

    final Widget view = _asyncState.when(
      skipLoadingOnRefresh: false,
      skipLoadingOnReload: false,
      data: (data) => originalView,
      loading: () {
        if (!enableListenBuilderLoading) return originalView;
        if (originalView is Scaffold) return _replaceScaffoldBody(originalView, Center(child: buildLoadingView()));
        return Center(child: buildLoadingView());
      },
      error: (error, stack) {
        if (!enableListenBuilderError) return originalView;
        final failure = error is Failure ? error : Failure(0, error.toString());
        if (originalView is Scaffold) return _replaceScaffoldBody(originalView, Center(child: buildErrorView(failure)));
        return Center(child: buildErrorView(failure));
      },
    );

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      behavior: HitTestBehavior.opaque,
      child: view,
    );
  }

  Scaffold _replaceScaffoldBody(Scaffold original, Widget newBody) {
    return Scaffold(
      key: original.key,
      appBar: original.appBar,
      body: newBody,
      floatingActionButton: original.floatingActionButton,
      floatingActionButtonLocation: original.floatingActionButtonLocation,
      floatingActionButtonAnimator: original.floatingActionButtonAnimator,
      persistentFooterButtons: original.persistentFooterButtons,
      persistentFooterAlignment: original.persistentFooterAlignment,
      drawer: original.drawer,
      onDrawerChanged: original.onDrawerChanged,
      endDrawer: original.endDrawer,
      onEndDrawerChanged: original.onEndDrawerChanged,
      bottomNavigationBar: original.bottomNavigationBar,
      bottomSheet: original.bottomSheet,
      backgroundColor: original.backgroundColor,
      resizeToAvoidBottomInset: original.resizeToAvoidBottomInset,
      primary: original.primary,
      drawerDragStartBehavior: original.drawerDragStartBehavior,
      extendBody: original.extendBody,
      extendBodyBehindAppBar: original.extendBodyBehindAppBar,
      drawerScrimColor: original.drawerScrimColor,
      drawerEdgeDragWidth: original.drawerEdgeDragWidth,
      drawerEnableOpenDragGesture: original.drawerEnableOpenDragGesture,
      endDrawerEnableOpenDragGesture: original.endDrawerEnableOpenDragGesture,
      restorationId: original.restorationId,
    );
  }
}