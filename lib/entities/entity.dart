import 'dart:ui';

import '../utils/math_utils.dart';

abstract class Entity {
  Vector2 position;
  Vector2 velocity;
  double width;
  double height;

  bool isActive = true;
  bool facingRight = true;

  Entity({
    required this.position,
    Vector2? velocity,
    required this.width,
    required this.height,
  }) : velocity = velocity ?? Vector2.zero();

  Rect get hitbox => Rect.fromLTWH(
        position.x - width / 2,
        position.y - height / 2,
        width,
        height,
      );

  double get left => position.x - width / 2;
  double get right => position.x + width / 2;
  double get top => position.y - height / 2;
  double get bottom => position.y + height / 2;

  Vector2 get center => position.copy();

  bool overlaps(Entity other) => hitbox.overlaps(other.hitbox);

  bool overlapsRect(Rect rect) => hitbox.overlaps(rect);

  void update(double dt);
}
