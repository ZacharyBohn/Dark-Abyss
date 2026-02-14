import 'dart:math';
import 'dart:ui';

import '../entities/player.dart';
import '../game/game_world.dart';
import '../utils/math_utils.dart';
import 'projectile.dart';
import 'spell.dart';

class FireballSpell extends Spell {
  FireballSpell()
      : super(
          name: 'Fireball',
          description: 'Launch a burning projectile that deals 40 damage',
          type: SpellType.fireball,
          manaCost: 20,
          cooldown: 1.5,
          castTime: 0, // Instant cast
        );

  @override
  void execute(Player player, GameWorld world) {
    // Get cast direction
    final direction = getCastDirection(player);

    // Create projectile
    final projectile = Projectile(
      position: player.position.copy(),
      velocity: direction * 600, // Fast projectile
      damage: 40,
      maxLifetime: 3.0,
      type: ProjectileType.fireball,
      radius: 10,
      color: const Color(0xFFFF6600),
    );

    // Add to spell manager
    world.spellManager.addProjectile(projectile);

    // Create cast particles
    _createCastEffect(player, world);
  }

  void _createCastEffect(Player player, GameWorld world) {
    // Create small burst of fire particles at cast point
    final direction = getCastDirection(player);
    for (var i = 0; i < 8; i++) {
      final angle = direction.angle + (i / 8 - 0.5) * 0.8;
      world.combat.addParticle(
        position: player.position.copy(),
        velocity: Vector2(cos(angle) * 150, sin(angle) * 150),
        lifetime: 0.3,
        color: const Color(0xFFFF6600),
        size: 4,
      );
    }
  }
}
