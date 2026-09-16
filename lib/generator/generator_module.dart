import 'dart:io';

void main(List<String> args) {
  if (args.isEmpty) {
    print('❌ Vui lòng nhập tên module. Ví dụ: dart run create_module.dart main_layout');
    exit(1);
  }

  final moduleName = args[0].toLowerCase();
  final className = _toPascalCase(moduleName);
  final varName = _toCamelCase(moduleName);
  final upperName = moduleName.toUpperCase();

  String packageName = 'untitled';
  final pubspecFile = File('pubspec.yaml');
  if (pubspecFile.existsSync()) {
    final lines = pubspecFile.readAsLinesSync();
    for (final line in lines) {
      if (line.trim().startsWith('name:')) {
        packageName = line.split(':')[1].trim();
        break;
      }
    }
  } else {
    print('⚠️ Không tìm thấy pubspec.yaml, sử dụng mặc định: $packageName');
  }

  print('🚀 Đang tạo module: $moduleName cho package: $packageName...');

  final featureDir = Directory('lib/feature/$moduleName');
  final presentationDir = Directory('${featureDir.path}/presentation');
  final routerDir = Directory('${featureDir.path}/router');

  presentationDir.createSync(recursive: true);
  routerDir.createSync(recursive: true);

  final routerFile = File('${routerDir.path}/${moduleName}_router.dart');
  if (!routerFile.existsSync()) {
    routerFile.writeAsStringSync('''
import 'package:flutter/material.dart';
import 'package:core_flutter/core_riverpod.dart';
import 'package:$packageName/feature/$moduleName/presentation/${moduleName}_view.dart';
import 'package:$packageName/router/app_router.dart';

final ${varName}Route = GoRoute(
  path: AppRouter.$varName,
  name: AppRouter.$varName,
  pageBuilder: (context, state) {
    return MaterialPage(
      key: state.pageKey,
      name: state.name ?? state.path,
      child: ProviderScope(
        child: ${className}View(args: state.extra),
      ),
    );
  },
);
''');
    print('✅ Đã tạo: ${routerFile.path}');
  } else {
    print('⚠️ Bỏ qua: ${routerFile.path} đã tồn tại.');
  }

  final stateFile = File('${presentationDir.path}/${moduleName}_state.dart');
  if (!stateFile.existsSync()) {
    stateFile.writeAsStringSync('''
/// ------------------------------------------------------------
/// AUTO-GENERATED STATE FILE FOR $className
/// ------------------------------------------------------------
/// File: lib/feature/$moduleName/presentation/${moduleName}_state.dart
///
/// ⚙️ How to automatically update this file:
///   Run the following command to generate `.freezed.dart`:
///     dart run build_runner build -d --build-filter="lib/feature/$moduleName/presentation/${moduleName}_state.dart"
///
/// This script will automatically generate or update:
///   • `copyWith`, `toString`, `==`, `hashCode` methods using `Freezed`
///
/// 💡 Notes:
///   • Add your variables inside the factory constructor.
///   • Example: `const factory ${className}State({ @Default(0) int count }) = _${className}State;`
/// ------------------------------------------------------------
library;

import 'package:core_flutter/core_riverpod.dart';

part '${moduleName}_state.freezed.dart';

@freezed
abstract class ${className}State with _\$${className}State {
  const ${className}State._();

  const factory ${className}State() = _${className}State;
}
''');
    print('✅ Đã tạo: ${stateFile.path}');
  }

  final notifierFile = File('${presentationDir.path}/${moduleName}_notifier.dart');
  if (!notifierFile.existsSync()) {
    notifierFile.writeAsStringSync('''
import 'package:core_flutter/core_riverpod.dart';
import 'package:$packageName/feature/$moduleName/presentation/${moduleName}_state.dart';

part '${moduleName}_notifier.g.dart';

@riverpod
class ${className}Notifier extends _\$${className}Notifier with BaseNotifier<${className}State> {

  @override
  ${className}State build(Object? args) {
    onInitStateBaseNotifier();
    ref.onDispose(onDisposeBaseNotifier);
    return const ${className}State();
  }
}
''');
    print('✅ Đã tạo: ${notifierFile.path}');
  }

  final viewFile = File('${presentationDir.path}/${moduleName}_view.dart');
  if (!viewFile.existsSync()) {
    viewFile.writeAsStringSync('''
import 'package:core_flutter/core_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:$packageName/feature/$moduleName/presentation/${moduleName}_notifier.dart';
import 'package:$packageName/feature/$moduleName/presentation/${moduleName}_state.dart';

class ${className}View extends BaseView<${className}Notifier, ${className}State> {
  final Object? args;
  ${className}View({this.args, super.key});

  @override
  ${className}Notifier readNotifier(WidgetRef ref) => ref.read(${varName}Provider(args).notifier);

  @override
  ${className}State watchState(WidgetRef ref) => ref.watch(${varName}Provider(args));

  @override
  Widget zBuilder() {
    return Scaffold(
      appBar: WidgetAppbar(
        title: const Text("$className view"),
      ),
    );
  }
}
''');
    print('✅ Đã tạo: ${viewFile.path}');
  }

  // 6. Xử lý app_router.dart
  final appRouterFile = File('lib/router/app_router.dart');
  if (!appRouterFile.existsSync()) {
    // Nếu chưa có app_router.dart (module đầu tiên)
    appRouterFile.parent.createSync(recursive: true);
    appRouterFile.writeAsStringSync('''
import 'package:core_flutter/core_riverpod.dart';
import 'package:$packageName/feature/$moduleName/router/${moduleName}_router.dart';

class AppRouter {
  static const String $varName = "/${upperName}_VIEW";

  static final init = GoRouter(
    initialLocation: ${varName}Route.path,
    navigatorKey: coreNavigatorKey,
    routes: [
      ${varName}Route,
    ],
  );
}
''');
    print('✅ Đã tạo: ${appRouterFile.path}');
  } else {
    // Nếu app_router.dart đã tồn tại, tự động tiêm code vào
    String appRouterContent = appRouterFile.readAsStringSync();
    final importString = "import 'package:$packageName/feature/$moduleName/router/${moduleName}_router.dart';\n";
    if (!appRouterContent.contains(importString)) {
      appRouterContent = importString + appRouterContent;
    }

    final constantString = '  static const String $varName = "/${upperName}_VIEW";\n';
    if (!appRouterContent.contains('static const String $varName =')) {
      appRouterContent = appRouterContent.replaceFirst('class AppRouter {\n', 'class AppRouter {\n$constantString');
    }

    final routeString = '      ${varName}Route,\n';
    if (!appRouterContent.contains('${varName}Route,')) {
      appRouterContent = appRouterContent.replaceFirst('routes: [\n', 'routes: [\n$routeString');
    }

    appRouterFile.writeAsStringSync(appRouterContent);
    print('✅ Đã tự động cập nhật route vào: ${appRouterFile.path}');
  }

  print('⏳ Đang chạy build_runner cho $moduleName (chỉ build thư mục này)...');
  final result = Process.runSync('dart', [
    'run',
    'build_runner',
    'build',
    '-d',
    '--build-filter=lib/feature/$moduleName/presentation/*.dart'
  ]);
  print(result.stdout);
  if (result.stderr.toString().isNotEmpty) {
    print('⚠️ Lỗi build_runner:');
    print(result.stderr);
  } else {
    print('✅ Chạy build_runner thành công!');
  }
  
  print('🎉 Hoàn tất! Bạn có thể xem module $moduleName tại thư mục lib/feature/$moduleName');
}

String _toCamelCase(String s) {
  final parts = s.split('_');
  if (parts.isEmpty) return '';
  final first = parts.first;
  final rest = parts.skip(1).map((p) => p.isEmpty ? '' : p[0].toUpperCase() + p.substring(1)).join('');
  return first + rest;
}

String _toPascalCase(String s) {
  final parts = s.split('_');
  return parts.map((p) => p.isEmpty ? '' : p[0].toUpperCase() + p.substring(1)).join('');
}