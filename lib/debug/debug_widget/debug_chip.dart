import 'package:core_riverpod/common/color_opacity.dart';
import 'package:core_riverpod/common/k.dart';
import 'package:flutter/material.dart';

class DebugChip extends StatelessWidget {
  final Color color;
  final String label;
  const DebugChip({
    this.color = K.kRed,
    this.label = "Label",
    super.key
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.darken(),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.op4),
      ),
      child: Text(
        label,
        style: K.style.copyWith(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
