import 'dart:ui';

class Platform {
  final double x;
  final double y;
  final double width;
  final double height;
  final bool isWall;
  final bool isOneWay; // Can jump through from below

  Platform({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.isWall = false,
    this.isOneWay = true, // Most platforms are one-way by default
  });

  Rect get rect => Rect.fromLTWH(x, y, width, height);

  double get left => x;
  double get right => x + width;
  double get top => y;
  double get bottom => y + height;
}
