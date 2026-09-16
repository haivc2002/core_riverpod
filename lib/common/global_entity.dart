import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'global_entity.g.dart';

/// ==========================================
/// 1. GLOBAL ACTION (Share Functions)
/// ==========================================
typedef ActionCallback = dynamic Function(dynamic data);

class GlobalAction {
  GlobalAction._();

  static final Map<String, ActionCallback> _actions = {};
  
  /// Expose for Debugger only
  static Map<String, ActionCallback> get debugActions => _actions;

  static void register(String key, ActionCallback action) {
    if (_actions.containsKey(key)) {
      throw Exception("GlobalEntity: The action with the key '$key' has already been registered!");
    }
    _actions[key] = action;
  }

  static void unregister(String key) {
    _actions.remove(key);
  }

  static dynamic dispatch(String key, [dynamic data]) {
    if (!_actions.containsKey(key)) {
      throw Exception("GlobalEntity: The action with the code '$key' has not been registered! Please check the code name.");
    }
    return _actions[key]!(data);
  }
}

/// ==========================================
/// 2. GLOBAL STATE (Share Reactive Variables)
/// ==========================================
@Riverpod(keepAlive: true)
class GlobalState extends _$GlobalState {
  @override
  dynamic build(String key) {
    return null;
  }

  void updateState(dynamic value) {
    state = value;
  }
}
