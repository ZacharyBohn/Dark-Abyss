import 'dart:math' as math;
import 'dart:ui';

import '../economy/currency_manager.dart';
import '../entities/enemy.dart';
import '../entities/pickup.dart';
import '../entities/player.dart';
import '../utils/math_utils.dart';
import 'damage_numbers.dart';
import 'particle_system.dart';

final _rng = math.Random();

class CombatSystem {
  final DamageNumberManager damageNumbers = DamageNumberManager();
  final ParticleSystem particles = ParticleSystem();

  // Currency manager reference (set by game world)
  CurrencyManager? currencyManager;

  // Pending pickups to spawn (handled by game world)
  final List<Pickup> pendingPickups = [];

  void update(double dt) {
    damageNumbers.update(dt);
    particles.update(dt);
  }

  /// Check player attacks against enemies
  void processPlayerAttacks(Player player, List<Enemy> enemies) {
    if (!player.isAttacking || player.attackHitThisSwing) return;

    final attackHitbox = player.attackHitbox;
    if (attackHitbox == null) return;

    for (final enemy in enemies) {
      if (enemy.isDead) continue;

      final enemyRect = enemy.hitbox;
      if (attackHitbox.overlaps(enemyRect)) {
        // Hit!
        player.attackHitThisSwing = true;

        var damage = player.attackDamage;
        final isCrit = player.critChance > 0 && _rng.nextDouble() < player.critChance;
        if (isCrit) {
          damage *= player.critMultiplier;
        }

        final knockbackDir = (enemy.position - player.position).normalized();
        enemy.takeDamage(damage, knockbackDirection: knockbackDir);

        // Life steal
        if (player.lifeStealPercent > 0) {
          final healAmount = damage * player.lifeStealPercent;
          player.heal(healAmount);
        }

        // Spawn effects
        final hitPos = Vector2(
          (player.position.x + enemy.position.x) / 2,
          (player.position.y + enemy.position.y) / 2,
        );

        damageNumbers.spawn(
          hitPos,
          damage,
          isCritical: isCrit || player.comboCount >= 3,
        );

        particles.spawnHitSparks(
          hitPos,
          isCrit ? const Color(0xFFFF4400) : const Color(0xFFFFAA00),
          count: isCrit ? 16 : (player.comboCount >= 3 ? 12 : 8),
        );

        // Check if enemy died
        if (enemy.isDead) {
          _handleEnemyDeath(enemy);
        }

        break; // Only hit one enemy per swing
      }
    }
  }

  /// Check enemy attacks/collision against player
  /// Enemies only deal damage when they are actively lunging (attacking)
  void processEnemyAttacks(Player player, List<Enemy> enemies) {
    if (player.hasIFrames || player.iFrameTimer > 0) return;

    for (final enemy in enemies) {
      if (enemy.isDead) continue;

      // Only deal damage when enemy is in lunge attack phase
      if (!enemy.isLunging) continue;

      // Check collision during lunge
      if (player.hitbox.overlaps(enemy.hitbox)) {
        player.takeDamage(enemy.damage, knockbackFrom: enemy.position);

        // Stop the lunge after hitting
        enemy.isLunging = false;

        damageNumbers.spawn(
          player.position,
          enemy.damage,
          isCritical: false,
        );

        particles.spawnHitSparks(
          player.position,
          const Color(0xFFFF4444),
          count: 6,
        );

        break; // Only take one hit per frame
      }
    }
  }

  /// Handle pickup collection
  void processPickups(Player player, List<Pickup> pickups) {
    final collectRadius = 20.0;

    for (final pickup in pickups) {
      if (pickup.collected) continue;

      final distance = player.position.distanceTo(pickup.position);
      if (distance < collectRadius) {
        pickup.collected = true;

        // Apply pickup effect
        switch (pickup.type) {
          case PickupType.health:
            player.heal(pickup.value.toDouble());
            damageNumbers.spawn(
              player.position,
              pickup.value.toDouble(),
              isHealing: true,
            );
            particles.spawnPickupEffect(
              pickup.position,
              const Color(0xFF00FF88),
            );
            break;

          case PickupType.energy:
            player.addEnergy(pickup.value.toDouble());
            particles.spawnPickupEffect(
              pickup.position,
              const Color(0xFF00AAFF),
            );
            break;

          case PickupType.coin:
            currencyManager?.addGold(pickup.value);
            damageNumbers.spawn(
              player.position + Vector2(0, -20),
              pickup.value.toDouble(),
              isGold: true,
            );
            particles.spawnPickupEffect(
              pickup.position,
              const Color(0xFFFFDD00),
            );
            break;

          case PickupType.essence:
            currencyManager?.addEssence(pickup.value);
            damageNumbers.spawn(
              player.position + Vector2(0, -20),
              pickup.value.toDouble(),
              isEssence: true,
            );
            particles.spawnPickupEffect(
              pickup.position,
              const Color(0xFFAA00FF),
            );
            break;
        }
      }
    }
  }

  void _handleEnemyDeath(Enemy enemy) {
    // Death burst particles
    particles.spawnDeathBurst(
      enemy.position,
      const Color(0xFFFF6600),
    );

    // Spawn drops using loot table
    final drops = enemy.getDrops();
    for (final drop in drops) {
      pendingPickups.add(Pickup(
        position: enemy.position.copy(),
        type: drop.type,
        customValue: drop.value,
      ));
    }
  }

  void clear() {
    damageNumbers.clear();
    particles.clear();
    pendingPickups.clear();
  }
}
