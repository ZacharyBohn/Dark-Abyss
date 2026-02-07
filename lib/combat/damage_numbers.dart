import 'dart:math';
import 'dart:ui';

import '../utils/math_utils.dart';

class DamageNumber {
  Vector2 position;
  double value;
  bool isCritical;
  bool isHealing;

  // Animation
  double lifetime = 1.0;
  double maxLifetime = 1.0;
  Vector2 velocity;
  double scale = 1.0;

  DamageNumber({
    required this.position,
    required this.value,
    this.isCritical = false,
    this.isHealing = false,
  }) : velocity = Vector2(
         (Random().nextDouble() - 0.5) * 50,
         -100 - Random().nextDouble() * 50,
       ) {
    if (isCritical) {
      scale = 1.5;
      maxLifetime = 1.5;
      lifetime = maxLifetime;
    }
  }

  void update(double dt) {
    lifetime -= dt;

    // Float upward with deceleration
    position.x += velocity.x * dt;
    position.y += velocity.y * dt;

    velocity.y += 100 * dt; // Slow down upward movement
    velocity.x *= 0.98;

    // Scale pop effect
    if (lifetime > maxLifetime - 0.1) {
      scale = lerpDouble(scale, isCritical ? 1.5 : 1.0, 0.2);
    }
  }

  bool get shouldRemove => lifetime <= 0;

  double get opacity => (lifetime / maxLifetime).clamp(0.0, 1.0);

  String get displayText {
    if (isHealing) {
      return '+${value.toInt()}';
    }
    return value.toInt().toString();
  }

  Color get color {
    if (isHealing) {
      return const Color(0xFF00FF88);
    }
    if (isCritical) {
      return const Color(0xFFFFAA00);
    }
    return const Color(0xFFFFFFFF);
  }
}

class DamageNumberManager {
  final List<DamageNumber> numbers = [];

  void spawn(Vector2 position, double value,
      {bool isCritical = false, bool isHealing = false}) {
    numbers.add(DamageNumber(
      position: position.copy(),
      value: value,
      isCritical: isCritical,
      isHealing: isHealing,
    ));
  }

  void update(double dt) {
    for (var i = numbers.length - 1; i >= 0; i--) {
      numbers[i].update(dt);
      if (numbers[i].shouldRemove) {
        numbers.removeAt(i);
      }
    }
  }

  void clear() {
    numbers.clear();
  }
}
