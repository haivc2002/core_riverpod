import 'package:core_riverpod/core_riverpod.dart';
import 'package:core_riverpod/debug/debug_notifier/debug_memory_notifier.dart';
import 'package:core_riverpod/debug/debug_notifier/debug_network_notifier.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

typedef DebugRouteItem = ({String name, int routeId});
typedef DebugPosState = ({
  double x,
  double y,
  bool isDragging,
  bool isOpen,
  int tabIndex,
  List<DebugRouteItem> routeStack,
});

class DebugNotifier extends Notifier<DebugPosState> {
  @override
  DebugPosState build() {
    if (kDebugMode) {
      Future.microtask(() {
        ref.read(debugMemoryProvider);
        ref.read(debugNetworkProvider);
      });
    }
    return (x: 0, y: 150, isDragging: false, isOpen: false, tabIndex: 0, routeStack: const []);
  }

  DebugPosState _copyWith({
    double? x,
    double? y,
    bool? isDragging,
    bool? isOpen,
    int? tabIndex,
    List<DebugRouteItem>? routeStack,
  }) {
    return (
      x: x ?? state.x,
      y: y ?? state.y,
      isDragging: isDragging ?? state.isDragging,
      isOpen: isOpen ?? state.isOpen,
      tabIndex: tabIndex ?? state.tabIndex,
      routeStack: routeStack ?? state.routeStack,
    );
  }

  void togglePanel() {
    state = _copyWith(isOpen: !state.isOpen);
  }

  void onDragStart() {
    state = _copyWith(isDragging: true);
  }

  void onDragUpdate(double dx, double dy, Size screenSize, EdgeInsets safeArea, double btnSize) {
    final newX = (state.x + dx).clamp(0.0, screenSize.width - btnSize);
    final maxY = screenSize.height - safeArea.bottom - btnSize;
    final minY = safeArea.top;
    final newY = (state.y + dy).clamp(minY, maxY);
    state = _copyWith(x: newX, y: newY);
  }

  void onDragEnd(Size screenSize, double btnSize) {
    final snapX = state.x < (screenSize.width / 2) ? 0.0 : (screenSize.width - btnSize);
    state = _copyWith(x: snapX, isDragging: false);
  }

  void setTabIndex(int index) {
    state = _copyWith(tabIndex: index);
  }

  void addScreen(String name, int routeId) {
    final newStack = List<DebugRouteItem>.from(state.routeStack)..add((name: name, routeId: routeId));
    state = _copyWith(routeStack: newStack);
  }

  void removeScreen(String name, int routeId) {
    final newStack = List<DebugRouteItem>.from(state.routeStack)
      ..removeWhere((e) => e.name == name && e.routeId == routeId);
    state = _copyWith(routeStack: newStack);

    ref.read(debugMemoryProvider.notifier).scheduleRetainCheck(name);
  }
}

final debugProvider = NotifierProvider<DebugNotifier, DebugPosState>(
  DebugNotifier.new,
);
