import '../entities/player.dart';
import '../game/game_world.dart';
import '../utils/math_utils.dart';

enum SpellType {
  fireball,
  frostNova,
  soulDrain,
  lightningBolt,
  shieldBarrier,
}

/// Base class for all spells
abstract class Spell {
  final String name;
  final String description;
  final SpellType type;
  final double manaCost;
  final double cooldown;
  final double castTime;

  // Current state
  double currentCooldown = 0;
  bool isCasting = false;
  double castTimer = 0;

  Spell({
    required this.name,
    required this.description,
    required this.type,
    required this.manaCost,
    required this.cooldown,
    required this.castTime,
  });

  /// Check if the spell can be cast
  bool canCast(Player player) {
    return currentCooldown <= 0 &&
        !isCasting &&
        player.currentMana >= manaCost;
  }

  /// Start casting the spell
  void startCast(Player player, GameWorld world) {
    if (!canCast(player)) return;

    if (player.consumeMana(manaCost)) {
      if (castTime > 0) {
        isCasting = true;
        castTimer = castTime;
      } else {
        // Instant cast
        execute(player, world);
        currentCooldown = cooldown;
      }
    }
  }

  /// Update spell state (cooldown, casting)
  void update(double dt, Player player, GameWorld world) {
    // Update cooldown
    if (currentCooldown > 0) {
      currentCooldown -= dt;
      if (currentCooldown < 0) currentCooldown = 0;
    }

    // Update casting
    if (isCasting) {
      castTimer -= dt;
      if (castTimer <= 0) {
        isCasting = false;
        execute(player, world);
        currentCooldown = cooldown;
      }
    }
  }

  /// Execute the spell effect
  void execute(Player player, GameWorld world);

  /// Get the direction the spell should be cast
  Vector2 getCastDirection(Player player) {
    // Default: facing direction
    return Vector2(player.facingRight ? 1 : -1, 0);
  }

  /// Get progress ratio for casting (0 to 1)
  double get castProgress {
    if (castTime == 0) return 1.0;
    return 1.0 - (castTimer / castTime);
  }

  /// Get progress ratio for cooldown (0 to 1, where 1 = ready)
  double get cooldownProgress {
    if (cooldown == 0) return 1.0;
    return 1.0 - (currentCooldown / cooldown);
  }
}
