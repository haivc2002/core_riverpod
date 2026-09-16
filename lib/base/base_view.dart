import "package:core_flutter/debug/debug_notifier/debug_memory_notifier.dart";
import "package:core_flutter/debug/debug_notifier/debug_panel_notifier.dart";
import "package:core_flutter/localization/core_messages.dart";
import "package:core_flutter/network/network_exception.dart";
import "package:core_flutter/widget/widget_wait.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:core_flutter/base/base_notifier.dart";
import "package:core_flutter/connectivity/connectivity_provider.dart";
import "package:core_flutter/common/global_entity.dart";
import "package:core_flutter/debug/debug_core.dart";

abstract class BaseView<N extends BaseNotifier<S>, S> extends HookConsumerWidget {
  BaseView({super.key});
  
  late BuildContext _context;
  late WidgetRef    _ref;
  late S            _state;
  late N            _notifier;

  bool          get isMounted                   => _context.mounted;
  BuildContext  get context                     => _context;
  WidgetRef     get ref                         => _ref;
  S             get state                       => _state;
  N             get viewModel                   => _notifier;
  bool          get enableListenBuilderLoading  => true;
  bool          get enableListenBuilderError    => true;

  S watchState(WidgetRef ref);

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
      if (!_context.mounted) return;
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
  Widget build(BuildContext context, WidgetRef ref) {
    if (kDebugMode) {
      ref.read(debugMemoryProvider);
      DebugMemoryNotifier.activeScreenName = runtimeType.toString();
      DebugMemoryNotifier.activeRouteId = ModalRoute.of(context)?.hashCode ?? 0;
    }
    _context  = context;
    _ref      = ref;
    _state    = watchState(ref);
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

    final screenState = useValueListenable(_notifier.stateNotifier);
    final Widget originalView = zBuilder(); 

    final Widget view = switch ((screenState, originalView)) {
      (ScreenStateEnum.LOADING, final Scaffold s) when enableListenBuilderLoading =>
          _replaceScaffoldBody(s, Center(child: buildLoadingView())),
          
      (ScreenStateEnum.ERROR, final Scaffold s) when enableListenBuilderError =>
          _replaceScaffoldBody(s, Center(child: buildErrorView(viewModel.viewObjectFailure))),
          
      (ScreenStateEnum.LOADING, _) when enableListenBuilderLoading =>
          Center(child: buildLoadingView()),
          
      (ScreenStateEnum.ERROR, _) when enableListenBuilderError =>
          Center(child: buildErrorView(viewModel.viewObjectFailure)),
          
      _ => originalView,
    };

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