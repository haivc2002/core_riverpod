import 'package:core_flutter/common/k.dart';
import 'package:flutter/material.dart';

class DebugFrame extends StatelessWidget {
  final String name;
  final Widget content;
  final Widget? trailing;
  final Color? borderColor;
  final Color? headerColor;
  final IconData? icon;

  const DebugFrame({
    required this.name,
    required this.content,
    this.trailing,
    this.borderColor,
    this.headerColor,
    this.icon,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBorder = borderColor ?? K.kBorder;
    final effectiveHeaderColor = headerColor ?? K.kBlue;

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: K.kDark,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: effectiveBorder, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: K.kNavi,
              border: Border(bottom: BorderSide(color: effectiveBorder, width: 1)),
              borderRadius: BorderRadius.vertical(top: Radius.circular(10))
            ),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 14, color: effectiveHeaderColor),
                  const SizedBox(width: 8),
                ] else ...[
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: effectiveHeaderColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    name.toUpperCase(),
                    style: K.style.copyWith(
                      color: effectiveHeaderColor,
                      letterSpacing: 1.1,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ?trailing,
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: content,
          ),
        ],
      ),
    );
  }
}
