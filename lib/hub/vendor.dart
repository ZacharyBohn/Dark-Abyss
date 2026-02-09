import '../utils/math_utils.dart';

enum VendorType {
  stat, // Sells stat upgrades for gold
  ability, // Sells ability unlocks for essence
  spell, // Sells spells for gold + essence
}

class Vendor {
  final VendorType type;
  final Vector2 position;
  final String name;
  final double interactionRadius;

  // Animation state
  double bobPhase = 0;
  double pulsePhase = 0;

  Vendor({
    required this.type,
    required this.position,
    required this.name,
    this.interactionRadius = 60.0,
  });

  void update(double dt) {
    bobPhase += 2.0 * dt;
    pulsePhase += 3.0 * dt;
  }

  bool isPlayerInRange(Vector2 playerPos) {
    return position.distanceTo(playerPos) < interactionRadius;
  }
}
