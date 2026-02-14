import 'dart:ui';

import '../entities/enemy.dart';
import '../entities/player.dart';
import '../game/game_world.dart';
import 'spell.dart';

class SoulDrainSpell extends Spell {
  static const double range = 120.0;
  static const double damagePerSecond = 30.0;
  static const double healPercent = 0.75; // Heal 75% of damage dealt

  SoulDrainSpell()
      : super(
          name: 'Soul Drain',
          description: 'Channel to drain HP from nearby enemies',
          type: SpellType.soulDrain,
          manaCost: 15,
          cooldown: 2.0,
          castTime: 0, // Instant start, but channels
        );

  @override
  void execute(Player player, GameWorld world) {
    // Find closest enemy in range
    Enemy? closestEnemy;
    var closestDist = double.infinity;

    for (var enemy in world.enemies) {
      final dx = enemy.position.x - player.position.x;
      final dy = enemy.position.y - player.position.y;
      final dist = dx * dx + dy * dy;

      if (dist <= range * range && dist < closestDist) {
        closestEnemy = enemy;
        closestDist = dist;
      }
    }

    if (closestEnemy != null) {
      // Deal damage
      final damage = damagePerSecond * 0.1; // Called per update tick
      world.combat.dealDamage(
        attacker: player,
        target: closestEnemy,
        damage: damage,
        isCrit: false,
      );

      // Heal player
      final healAmount = damage * healPercent;
      player.heal(healAmount);

      // Show healing damage number on player
      world.combat.addDamageNumber(
        position: player.position.copy(),
        value: healAmount,
        isHealing: true,
      );

      // Create drain particles (from enemy to player)
      final direction = (player.position - closestEnemy.position).normalized();
      for (var i = 0; i < 2; i++) {
        world.combat.addParticle(
          position: closestEnemy.position.copy(),
          velocity: direction * 200,
          lifetime: 0.3,
          color: const Color(0xFFAA00FF),
          size: 4,
        );
      }
    }
  }

  @override
  void update(double dt, Player player, GameWorld world) {
    // Override update to handle continuous drain
    if (currentCooldown > 0) {
      currentCooldown -= dt;
      if (currentCooldown < 0) currentCooldown = 0;
    }

    // Note: Soul Drain is instant cast but could be made into a channeled spell
    // For now, keeping it simple as a quick drain burst
  }
}
