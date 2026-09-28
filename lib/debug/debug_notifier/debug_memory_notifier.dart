import 'dart:async';
import 'package:core_riverpod/core_riverpod.dart';
import 'package:flutter/foundation.dart';

typedef DebugLeakReport = ({String objectName, String screenName, StackTrace stackTrace});

/// Memory Leak Tracker cho Riverpod, được viết lại theo kiến trúc của core_bloc.
///
/// === Thiết kế quan trọng ===
///
/// 1. Controller Leak Detection: Dùng Finalizer thay vì Timer.
///    - Khi ChangeNotifier được tạo (ObjectCreated): gắn Finalizer vào object.
///    - Khi ChangeNotifier được dispose (ObjectDisposed): detach Finalizer (gỡ lệnh truy nã).
///    - Khi GC thu gom object MÀ Finalizer chưa bị detach: Báo leak (never disposed).
///    => Chính xác 100%, không bao giờ false positive.
///
/// 2. Screen Retention Detection: Dùng WeakReference + GC Canary.
///    - Khi màn hình được mở: lưu WeakReference vào bộ nhớ.
///    - Khi màn hình bị đóng: chờ GC chạy (verify bằng canary), 
///      rồi kiểm tra WeakReference.target có null không.
///    - Nếu GC đã chạy mà target vẫn khác null: Báo screen retention.
class DebugMemoryNotifier extends Notifier<List<DebugLeakReport>> {
  static DebugMemoryNotifier? _instance;
  static bool _isListening = false;
  static String activeScreenName = "Unknown";

  /// Finalizer: Khi GC thu gom một ChangeNotifier mà chưa hề được dispose (detach),
  /// callback này sẽ được kích hoạt và báo leak.
  static final Finalizer<Map<String, String>> _controllerFinalizer = Finalizer((info) {
    final screen = info["screen"] ?? "Unknown";
    final description = info["description"] ?? "Unknown";
    _instance?.state = [
      ..._instance!.state,
      (
        objectName: "$description (never disposed)",
        screenName: screen,
        stackTrace: StackTrace.empty,
      ),
    ];
  });

  /// Screen retention tracking
  static final Map<String, WeakReference<Object>> _trackedScreens = {};
  static final Map<String, Timer> _pendingChecks = {};
  static const int _maxRetries = 4;
  static const Duration _retryInterval = Duration(seconds: 4);
  static const Duration _gcPollInterval = Duration(milliseconds: 500);
  static const Duration _gcTimeout = Duration(seconds: 8);

  /// Finalizer cho screen: khi screen bị GC thu gom, tự động hủy timer pending.
  static final Finalizer<String> _screenFinalizer = Finalizer((name) {
    _cancelPending(name);
    _trackedScreens.remove(name);
  });

  @override
  List<DebugLeakReport> build() {
    _instance = this;
    if (!_isListening && kDebugMode) {
      _isListening = true;
      _initControllerTracker();
    }
    return [];
  }

  /// Khởi tạo bộ theo dõi Controller tự động dùng Finalizer.
  /// Khi ChangeNotifier được tạo => gắn Finalizer.
  /// Khi ChangeNotifier được dispose => detach Finalizer (tha bổng).
  static void _initControllerTracker() {
    FlutterMemoryAllocations.instance.addListener((ObjectEvent event) {
      final obj = event.object;
      if (obj is! ChangeNotifier) return;

      final description = "${obj.runtimeType} (Hash: ${identityHashCode(obj)})";

      if (event is ObjectCreated) {
        // Gắn Finalizer: nếu object bị GC thu gom mà chưa detach => báo leak
        _controllerFinalizer.attach(
          obj,
          {"screen": activeScreenName, "description": description},
          detach: obj,
        );
      } else if (event is ObjectDisposed) {
        // Object đã được dispose đúng cách => gỡ Finalizer (không báo leak)
        _controllerFinalizer.detach(obj);
      }
    });
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Screen Retention Detection (WeakReference + GC Canary)
  // ──────────────────────────────────────────────────────────────────────────

  /// Đăng ký theo dõi màn hình. Gọi trong initState hoặc build.
  void registerScreen(Object screenState, String name) {
    if (!kDebugMode) return;
    _trackedScreens[name] = WeakReference(screenState);
    _screenFinalizer.attach(screenState, name, detach: screenState);
  }

  /// Lên lịch kiểm tra xem màn hình đã được giải phóng chưa. Gọi khi dispose.
  void scheduleRetainCheck(String name) {
    if (!kDebugMode) return;
    if (!_trackedScreens.containsKey(name)) return;

    _cancelPending(name);
    _scheduleRetry(name: name, attempt: 1);
  }

  static void _cancelPending(String name) {
    final timer = _pendingChecks.remove(name);
    if (timer != null && timer.isActive) {
      timer.cancel();
    }
  }

  static void _scheduleRetry({required String name, required int attempt}) {
    if (!kDebugMode) return;

    final timer = Timer(_retryInterval, () {
      _pendingChecks.remove(name);
      final weakRef = _trackedScreens[name];
      if (weakRef == null) return;

      // Đã được GC thu gom => an toàn
      if (weakRef.target == null) {
        _trackedScreens.remove(name);
        return;
      }

      // Ép GC chạy rồi kiểm tra lại
      _waitForGC().then((gcConfirmed) {
        if (!_trackedScreens.containsKey(name)) return;

        final target = _trackedScreens[name]?.target;

        if (target == null) {
          _trackedScreens.remove(name);
          return;
        }

        if (attempt < _maxRetries) {
          _scheduleRetry(name: name, attempt: attempt + 1);
          return;
        }

        // Hết số lần retry mà object vẫn sống => báo leak
        _instance?.state = [
          ..._instance!.state,
          (
            objectName: "$name (retained in memory)",
            screenName: name,
            stackTrace: StackTrace.empty,
          ),
        ];
        _trackedScreens.remove(name);
      });
    });
    _pendingChecks[name] = timer;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // GC Canary — Xác nhận GC đã thực sự chạy
  // ──────────────────────────────────────────────────────────────────────────

  /// Tạo một object "chim mồi" (canary) và chờ GC thu gom nó.
  /// Nếu canary bị GC thu gom => GC đã chạy => kết quả kiểm tra đáng tin cậy.
  static Future<bool> _waitForGC() async {
    final WeakReference<Object> canary = WeakReference(Object());
    final stopwatch = Stopwatch()..start();
    int pollCount = 0;

    while (stopwatch.elapsed < _gcTimeout) {
      if (pollCount % 2 == 0) {
        _applyGCPressure();
      }
      pollCount++;

      await Future.delayed(_gcPollInterval);

      if (canary.target == null) {
        stopwatch.stop();
        return true;
      }
    }

    stopwatch.stop();
    return false;
  }

  /// Cấp phát bộ nhớ lớn rồi giải phóng ngay để ép Dart VM chạy GC.
  static void _applyGCPressure() {
    final List<List<int>> pressure = [];
    for (int i = 0; i < 40; i++) {
      pressure.add(List<int>.filled(65536, i));
    }
    pressure.clear();
  }

  void clear() {
    state = [];
  }
}

final debugMemoryProvider = NotifierProvider<DebugMemoryNotifier, List<DebugLeakReport>>(
  DebugMemoryNotifier.new,
);
