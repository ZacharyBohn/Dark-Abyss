import 'dart:math';

import '../utils/math_utils.dart';

/// Portal to the next floor
class ExitPortal {
  Vector2 position;
  final double radius;

  // Animation state
  double rotationAngle = 0;
  double pulsePhase = 0;
  bool isActive = true;

  // Activation (requires all enemies defeated)
  bool isUnlocked = false;

  ExitPortal({
    required this.position,
    this.radius = 40,
  });

  void update(double dt) {
    rotationAngle += dt * 2;
    pulsePhase += dt * 4;
  }

  double get pulseScale => 1.0 + sin(pulsePhase) * 0.1;

  bool containsPoint(Vector2 point) {
    return (position - point).length < radius;
  }

  /// Check if player is close enough to activate
  bool isPlayerInRange(Vector2 playerPos) {
    return (position - playerPos).length < radius * 1.5;
  }
}
