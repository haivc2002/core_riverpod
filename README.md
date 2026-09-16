# 🚀 Core Flutter Framework

Đây là bộ Core Framework được thiết kế tối ưu, tập trung vào kiến trúc Clean Architecture, hiệu suất cao và tích hợp sẵn bộ công cụ Debug mạnh mẽ (Cyberpunk UI) dành riêng cho nội bộ dự án.

## 📦 Kiến trúc & Tính năng nổi bật

1. **State Management**: Sử dụng `Riverpod` với kiến trúc `BaseNotifier` và `BaseView`, tách biệt hoàn toàn Logic và UI.
2. **Global Entity**:
   - `GlobalAction`: Đăng ký và gọi các hàm dùng chung ở bất kỳ đâu thông qua `key`.
   - `GlobalState`: Quản lý state toàn cục.
3. **Network Layer**: Dựa trên `Dio`, tự động xử lý Error (Interceptor) và ghi log vào Debug Panel.
4. **Storage**: Hỗ trợ đồng thời `SharedPreferences` và `FlutterSecureStorage` (Keychain/Keystore).
5. **In-App Debugger (DevTools)**: Bảng điều khiển ẩn trong App giúp test ngay trên thiết bị thật: theo dõi Route, RAM (Memory Leaks), API log, và Storage Inspector.

---

## ⚙️ Cài đặt & Tích hợp vào dự án chính

Để dự án chính sử dụng được `core_flutter`, bạn cần khai báo path local trong `pubspec.yaml` của dự án chính:

```yaml
dependencies:
  flutter:
    sdk: flutter
  core_flutter:
    path: ./core_flutter  # Trỏ đường dẫn tới thư mục core
```

Sau đó chạy lệnh:
```bash
flutter pub get
```

### Cấu hình Linter (`analysis_options.yaml`)
Để tránh việc Flutter cảnh báo vàng (warning) liên quan đến tính bất biến của Widget (do đặc thù kiến trúc linh hoạt của BaseView/BaseNotifier trong Core), bạn cần bổ sung config sau vào file `analysis_options.yaml` của **dự án chính**:

```yaml
analyzer:
  errors:
    must_be_immutable: ignore
```

---

## 🛠 Cấu hình `Makefile` (Lệnh Terminal)

Bộ core đi kèm với một file `Makefile` cực kỳ tiện lợi để chạy các script sinh code tự động (Generator) và build_runner. 

⚠️ **Quan trọng:** File `Makefile` hiện đang nằm trong thư mục `core_flutter`. Để tiện gõ lệnh trên terminal ở thư mục gốc của dự án chính, bạn cần **chép (copy) file `Makefile` này ra ngoài thư mục gốc (root)**.

```bash
# Đứng từ thư mục root của dự án, chạy lệnh:
cp core_flutter/Makefile ./
```

### Các lệnh `make` có sẵn (chạy ở thư mục gốc):

- **`make build`**: Chạy `build_runner` toàn bộ dự án (Dùng khi cập nhật Riverpod, Freezed).
- **`make layout`**: Build siêu tốc chỉ định riêng cho `layout_registry.g.dart`.
- **`make filter file="<đường_dẫn>"`**: Build cho một file cụ thể để tiết kiệm thời gian.
- **`make gen <tên_module>`**: Tự động sinh ra cấu trúc thư mục và các file Boilerplate (View, State, Notifier) cho một chức năng mới.
  - Ví dụ: `make gen login` (Hệ thống sẽ tạo ra toàn bộ luồng Login chuẩn kiến trúc vào thư mục feature).

---

## 📖 Hướng dẫn sử dụng nhanh

### 1. Storage (Lưu trữ dữ liệu)
```dart
import 'package:core_flutter/common/storage.dart';

// SharedPreferences (Key-Value thường)
Storage.setString('username', 'admin');
String name = Storage.getString('username');

// Secure Storage (Lưu token bảo mật vào Keychain/Keystore)
await Storage.setSecureString('access_token', 'eyJhbGciOi...');
String? token = await Storage.getSecureString('access_token');
```

### 2. GlobalAction (Chạy hàm xuyên màn hình)
Đăng ký hàm ở một nơi, gọi ở một nơi khác mà không cần truyền tham số rườm rà.
```dart
// Đăng ký ở đâu đó (vd: Khởi tạo App)
GlobalAction.register('SHOW_SNACKBAR', (data) {
  print("Đang hiển thị snackbar: $data");
});

// Gọi ở bất cứ đâu trong App
GlobalAction.dispatch('SHOW_SNACKBAR', 'Lưu thành công!');
```
*💡 Mẹo: Bấm vào tab Memory trên In-App Debugger để xem tất cả Action đang được đăng ký.*

### 3. Hiển thị In-App Debugger
Bọc toàn bộ App của bạn bằng Overlay để kích hoạt Debugger (Cyberpunk Panel):
```dart
import 'package:core_flutter/debug/debug_core.dart';

MaterialApp(
  builder: (context, child) {
    // Chỉ kích hoạt khi kDebugMode == true
    return CoreDebugOverlay(child: child!); 
  },
);
```

---
*Developed & Optimized for High-Performance Flutter Apps.*
