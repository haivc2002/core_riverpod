import 'package:flutter/material.dart';

class WidgetAvatar extends StatelessWidget {
  final String? name;
  final String? avatar;
  final double radius;

  const WidgetAvatar({
    super.key,
    this.name,
    this.avatar,
    this.radius = 20,
  });

  static const List<Color> _colors = [
    Color(0xFFE57373),
    Color(0xFF64B5F6),
    Color(0xFF81C784),
    Color(0xFFFFB74D),
    Color(0xFFBA68C8),
    Color(0xFF4DB6AC),
    Color(0xFFFF8A65),
    Color(0xFFA1887F),
    Color(0xFF90A4AE),
    Color(0xFFF06292),
  ];

  Color get _backgroundColor => switch (name?.trim()) {
    null || '' => Colors.grey,
    final String n => _colors[n.toUpperCase().codeUnitAt(0) % _colors.length],
  };

  Widget get _fallbackChild => switch (name?.trim()) {
    null || '' => Icon(Icons.person, color: Colors.white, size: radius * 1.2),
    final String n => Text(
        n.characters.first.toUpperCase(),
        style: TextStyle(
          color: Colors.white,
          fontSize: radius * 0.9,
          fontWeight: FontWeight.bold,
        ),
      ),
  };

  Widget _buildFallback() {
    return CircleAvatar(
      radius: radius,
      backgroundColor: _backgroundColor,
      child: _fallbackChild,
    );
  }

  @override
  Widget build(BuildContext context) => switch (avatar?.trim()) {
    null || '' => _buildFallback(),
    final String url => Container(
        width: radius * 2,
        height: radius * 2,
        decoration: const BoxDecoration(shape: BoxShape.circle),
        clipBehavior: Clip.antiAlias,
        child: Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _buildFallback(),
        ),
      ),
  };
}