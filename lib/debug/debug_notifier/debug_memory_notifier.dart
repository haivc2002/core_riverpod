import 'dart:async';
import 'package:core_flutter/core_riverpod.dart';
import 'package:flutter/foundation.dart';

typedef DebugLeakReport = ({String objectName, String screenName, StackTrace stackTrace});

class DebugMemoryNotifier extends Notifier<List<DebugLeakReport>> {
  static DebugMemoryNotifier? _instance;
  static bool _isListening = false;
  static String activeScreenName = "Unknown";
  static int activeRouteId = -1;

  static final Map<int, Set<int>> _routeObjects = {};
  static final Map<int, ({String objectName, String screenName, int routeId})> _objectInfo = {};
  static final Set<int> _disposedObjects = {};

  @override
  List<DebugLeakReport> build() {
    _instance = this;
    if (!_isListening && kDebugMode) {
      _isListening = true;
      FlutterMemoryAllocations.instance.addListener(_onMemoryEvent);
    }
    return [];
  }

  static void _onMemoryEvent(ObjectEvent event) {
    final obj = event.object;
    if (obj is! ChangeNotifier) return;

    final hash = identityHashCode(obj);

    if (event is ObjectCreated) {
      final rId = activeRouteId;
      if (rId == -1) return;

      _routeObjects.putIfAbsent(rId, () => {}).add(hash);
      _objectInfo[hash] = (
        objectName: obj.runtimeType.toString(),
        screenName: activeScreenName,
        routeId: rId,
      );
    } else if (event is ObjectDisposed) {
      _disposedObjects.add(hash);
    }
  }

  void track(ChangeNotifier obj, String name, {int? routeId, String? screenName}) {
    if (!kDebugMode) return;

    final hash = identityHashCode(obj);
    final rId = routeId ?? activeRouteId;
    final sName = screenName ?? activeScreenName;

    _routeObjects.putIfAbsent(rId, () => {}).add(hash);
    _objectInfo[hash] = (objectName: name, screenName: sName, routeId: rId);
  }

  void clear() {
    state = [];
  }

  void checkRouteId(int routeId) {
    if (!kDebugMode) return;

    final objectHashes = _routeObjects.remove(routeId);
    if (objectHashes == null || objectHashes.isEmpty) return;
    Future.delayed(const Duration(milliseconds: 1000), () {
      final leaks = <DebugLeakReport>[];

      for (final hash in objectHashes) {
        final info = _objectInfo.remove(hash);
        if (info == null) continue;

        if (_disposedObjects.contains(hash)) {
          _disposedObjects.remove(hash);
        } else {
          leaks.add((
            objectName: "${info.objectName} (never disposed)",
            screenName: info.screenName,
            stackTrace: StackTrace.empty,
          ));
        }
      }

      if (leaks.isNotEmpty && _instance != null) {
        _instance!.state = [..._instance!.state, ...leaks];
      }
    });
  }
}

final debugMemoryProvider = NotifierProvider<DebugMemoryNotifier, List<DebugLeakReport>>(
  DebugMemoryNotifier.new,
);
