import 'package:flutter/material.dart';

class WidgetLayout extends StatelessWidget {
  final Widget Function(ViewDevice device) builder;
  const WidgetLayout({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        final device = ViewDevice.fromConstraints(constraints);
        return builder(device);
      },
    );
  }
}

class ViewDevice {
  final bool isTablet;
  final bool isMobile;

  ViewDevice({required this.isTablet, required this.isMobile});
  factory ViewDevice.fromConstraints(BoxConstraints constraints) {
    final width = constraints.maxWidth;
    if (width >= 600) {
      return ViewDevice(isTablet: true, isMobile: false);
    } else {
      return ViewDevice(isTablet: false, isMobile: true);
    }
  }
}

