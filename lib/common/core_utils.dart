import 'dart:developer' as dev;
import 'package:core_riverpod/common/k.dart';
import 'package:core_riverpod/overlay_ui/overlay_bottom.dart';
import 'package:core_riverpod/overlay_ui/overlay_dialog.dart';
import 'package:core_riverpod/overlay_ui/overlay_snack_bar.dart';
import 'package:core_riverpod/widget/widget_wait.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:core_riverpod/localization/core_messages.dart';

void coreLog(String message,
    {String name = K.nameCore,
      StackTrace? stackTrace,
      Object? error
    }) {
  if(kDebugMode) {
    dev.log(message,
      name: name,
      stackTrace: stackTrace,
      error: error
  );}
}

final Iterable<Locale> coreSupportedLocales  = [
  Locale(K.vi),
  Locale(K.en),
  Locale(K.zh),
  Locale(K.ja),
  Locale(K.ko),
  Locale(K.es),
  Locale(K.fr),
];

GlobalKey<NavigatorState> coreNavigatorKey = GlobalKey<NavigatorState>();

/// Internal helper to resolve the most appropriate context for UI operations.
BuildContext get _currentContext {
  if(coreNavigatorKey.currentContext == null) {
    throw Exception("'coreNavigatorKey' has not been configured.\n"
        "Please add it to your GoRouter configuration:\n"
        "```\n"
        "static final init = GoRouter(\n"
        "\tnavigatorKey: coreNavigatorKey, // 👈 Configure here\n"
        "\t// ...\n"
        ");\n"
        "```");
  }
  return coreNavigatorKey.currentContext!;
}

/// Pushes a named route onto the navigator stack.
Future<T?> pushNamed<T extends Object?>(String name, {Object? args}) {
  return _currentContext.pushNamed<T>(name, extra: args);
}

/// Replaces the current route with a new named route.
void pushReplacementNamed(String name, {Object? args}) {
  _currentContext.pushReplacementNamed(name, extra: args);
}

/// Equivalent to pushNamedAndRemoveUntil in traditional Navigator.
/// In GoRouter, [goNamed] acts similarly by navigating to a destination 
/// and clearing the stack based on the route hierarchy.
void pushNamedAndRemoveAll(String name, {Object? args}) {
  _currentContext.goNamed(name, extra: args);
}

/// Pops the current route from the navigator stack.
void back<T>([T? result]) {
  if (_currentContext.canPop()) {
    _currentContext.pop<T>(result);
  }
}

/// Pops all routes until the first route is reached.
/// GoRouter doesn't have popUntil, so we pop continuously while possible.
void backToFirst() {
  while (_currentContext.canPop()) {
    _currentContext.pop();
  }
}

/// Jumps back to a specific route.
/// In GoRouter, you should just use [goNamed] to declaratively jump back to an ancestor route.
void backToUntil(String name, {Object? args}) {
  _currentContext.goNamed(name, extra: args);
}

/// Shows a custom dialog using the core's OverlayDialog widget.
Future<void> coreDialog({
  String title                = "",
  Widget body                 = const SizedBox(),
  List<ButtonAction> actions  = const [],
  bool canPop                 = true,
  bool disEnableActions       = false
}) {
  return showCupertinoDialog(
    context: _currentContext,
    builder: (_) => PopScope(
      canPop: canPop,
      child: OverlayDialog(
        body: body,
        title: title,
        actions: actions,
        disEnableActions: disEnableActions,
      ),
    ),
  );
}

/// Shows a custom bottom sheet.
Future<void> coreBottomSheet({
  Widget? body,
  String title = "",
  List<ButtonAction> actions = const [],
}) async {
  return showModalBottomSheet(
    context: _currentContext,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => OverlayBottom(
      title: title,
      body: body ?? const SizedBox(),
      actions: actions,
    ),
  );
}

/// Opens a global loading overlay that blocks user interaction.
Future<void> openLoadingOverlay() {
  return showCupertinoDialog(
    barrierColor: Colors.black26,
    context: _currentContext,
    builder: (context) => PopScope(
      canPop: false,
      child: Material(
        color: Colors.transparent,
        child: Center(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: WidgetWait(color: Colors.white),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Closes the currently active loading overlay.
void closeLoadingOverlay() => back();

/// Displays a success notification using a SnackBar.
void successSnackBar(String message, {String? title}) =>
    _showSnackBar(message, status: _Status.success, title: title);

/// Displays an error notification using a SnackBar.
void errorSnackBar(String message, {String? title}) =>
    _showSnackBar(message, status: _Status.failure, title: title);

/// Displays a warning notification using a SnackBar.
void warningSnackBar(String message, {String? title}) =>
    _showSnackBar(message, status: _Status.warning, title: title);

void coreSnackBar(String message) =>
    _showSnackBar(message, status: _Status.normal);

/// Internal helper to display a custom SnackBar with status-based styling.
void _showSnackBar(String message, {required _Status status, String? title}) {
  Color color = Colors.green;
  IconData? icon = Icons.check_circle;
  Color textColor = Colors.white;

  switch (status) {
    case _Status.failure:
      color = Colors.red;
      title = title ?? CoreMessages.of(_currentContext).failure;
      icon = Icons.error;
      break;
    case _Status.warning:
      color = const Color(0xFFFAA134);
      title = title ?? CoreMessages.of(_currentContext).notification;
      icon = Icons.warning_rounded;
      break;
    case _Status.success:
      color = Colors.green;
      title = title ?? CoreMessages.of(_currentContext).success;
      icon = Icons.check_circle;
      break;
    case _Status.normal:
      color = Theme.of(_currentContext).snackBarTheme.backgroundColor ??
          Theme.of(_currentContext).colorScheme.surfaceContainerHighest;
      textColor = Theme.of(_currentContext).colorScheme.onSurface;
      icon = null;
      title = null;
      break;
  }

  ScaffoldMessenger.of(_currentContext).showSnackBar(
    SnackBar(
      duration: const Duration(seconds: 3),
      backgroundColor: Colors.transparent,
      elevation: 0,
      content: OverlaySnackBar(
        color,
        icon,
        message,
        title,
        textColor: textColor,
      ),
    ),
  );
}

/// Internal enumeration for SnackBar status states.
enum _Status {
  failure,
  normal,
  warning,
  success
}