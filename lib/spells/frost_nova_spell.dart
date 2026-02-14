import 'dart:math';
import 'dart:ui';

import '../entities/player.dart';
import '../game/game_world.dart';
import '../utils/math_utils.dart';
import 'spell.dart';

class FrostNovaSpell extends Spell {
  static const double radius = 200.0;
  static const double damage = 25.0;
  static const double slowDuration = 2.0;
  static const double slowAmount = 0.5; // Reduce speed by 50%

  FrostNovaSpell()
      : super(
          name: 'Frost Nova',
          description: 'AOE freeze around player, 25 damage, slows enemies',
          type: SpellType.frostNova,
          manaCost: 35,
          cooldown: 4.0,
          castTime: 0, // Instant cast
        );

  @override
  void execute(Player player, GameWorld world) {
    // Create frost nova visual effect
    _createNovaEffect(player, world);

    // Damage and slow all enemies in range
    for (var enemy in world.enemies) {
      final dx = enemy.position.x - player.position.x;
      final dy = enemy.position.y - player.position.y;
      final distanceSq = dx * dx + dy * dy;

      if (distanceSq <= radius * radius) {
        // Deal damage
        world.combat.dealDamage(
          attacker: player,
          target: enemy,
          damage: damage,
          isCrit: false,
        );

        // Apply slow effect
        enemy.applySlowEffect(slowDuration, slowAmount);

        // Create hit particles
        for (var i = 0; i < 8; i++) {
          final angle = (i / 8) * 3.14159 * 2;
          world.combat.addParticle(
            position: enemy.position.copy(),
            velocity: Vector2(cos(angle) * 100, sin(angle) * 100),
            lifetime: 0.4,
            color: const Color(0xFF00DDFF),
            size: 3,
          );
        }
      }
    }
  }

  void _createNovaEffect(Player player, GameWorld world) {
    // Create expanding ring of frost particles
    const particleCount = 36;
    for (var i = 0; i < particleCount; i++) {
      final angle = (i / particleCount) * 3.14159 * 2;
      final speed = 300.0;
      world.combat.addParticle(
        position: player.position.copy(),
        velocity: Vector2(cos(angle) * speed, sin(angle) * speed),
        lifetime: 0.5,
        color: const Color(0xFF00DDFF),
        size: 5,
      );
    }

    // Add some inner particles for effect
    for (var i = 0; i < 20; i++) {
      final angle = (i / 20) * 3.14159 * 2;
      final speed = 150.0;
      world.combat.addParticle(
        position: player.position.copy(),
        velocity: Vector2(cos(angle) * speed, sin(angle) * speed),
        lifetime: 0.3,
        color: const Color(0xFFAAFFFF),
        size: 3,
      );
    }
  }
}
