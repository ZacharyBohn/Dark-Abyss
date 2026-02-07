import 'dart:math';

import '../utils/math_utils.dart';
import 'enemy.dart';

class Pickup {
  Vector2 position;
  Vector2 velocity;
  PickupType type;

  double width = 16;
  double height = 16;

  // Animation
  double bobPhase;
  double bobSpeed = 4.0;
  double bobAmount = 5.0;
  double pulsePhase;

  // Lifetime
  double lifetime = 10.0;
  double blinkTimer = 0;
  bool collected = false;

  // Magnet effect
  bool beingPulled = false;
  double pullSpeed = 0;

  Pickup({
    required this.position,
    required this.type,
    Vector2? initialVelocity,
  }) : velocity = initialVelocity ?? Vector2(
         (Random().nextDouble() - 0.5) * 200,
         -200 - Random().nextDouble() * 100,
       ),
       bobPhase = Random().nextDouble() * pi * 2,
       pulsePhase = Random().nextDouble() * pi * 2;

  void update(double dt, Vector2? playerPosition) {
    // Apply gravity
    velocity.y += 500 * dt;

    // Apply friction
    velocity.x *= 0.98;

    // Apply velocity
    position.x += velocity.x * dt;
    position.y += velocity.y * dt;

    // Ground collision (simple)
    if (velocity.y > 0) {
      velocity.y *= 0.8;
      if (velocity.y.abs() < 10) {
        velocity.y = 0;
      }
    }

    // Animation
    bobPhase += bobSpeed * dt;
    pulsePhase += 5.0 * dt;

    // Lifetime
    lifetime -= dt;
    if (lifetime < 3.0) {
      blinkTimer += dt * 10;
    }

    // Magnet effect - pull toward player when close
    if (playerPosition != null) {
      final distance = position.distanceTo(playerPosition);
      if (distance < 80) {
        beingPulled = true;
        pullSpeed += 500 * dt;
        pullSpeed = pullSpeed.clamp(0, 800);

        final direction = (playerPosition - position).normalized();
        position.x += direction.x * pullSpeed * dt;
        position.y += direction.y * pullSpeed * dt;
      }
    }
  }

  bool get shouldRemove => collected || lifetime <= 0;

  bool get isBlinking => lifetime < 3.0 && (blinkTimer % 1.0) > 0.5;

  double get bobOffset => sin(bobPhase) * bobAmount;

  double get pulseScale => 1.0 + sin(pulsePhase) * 0.1;

  // Get the value of this pickup
  int get value {
    switch (type) {
      case PickupType.health:
        return 20;
      case PickupType.energy:
        return 10;
      case PickupType.coin:
        return 5;
      case PickupType.essence:
        return 1;
    }
  }
}
