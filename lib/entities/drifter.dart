import 'dart:math';

import '../utils/math_utils.dart';
import 'enemy.dart';

/// Drifter - The simplest enemy
/// A floating geometric shape that drifts toward the player
/// Low damage, low health, drops energy
class Drifter extends Enemy {
  // Unique movement properties
  double wobblePhase = 0;
  double wobbleSpeed = 3.0;
  double wobbleAmount = 20.0;

  // Visual properties
  int shapeType; // 0 = triangle, 1 = square, 2 = pentagon
  double pulsePhase = 0;

  // Attack wind-up and lunge
  double windupTimer = 0;
  double lungeTimer = 0;
  Vector2 lungeDirection = Vector2.zero();
  static const double windupDuration = 0.4; // Wind-up time before lunge
  static const double lungeDuration = 0.15; // Fast lunge duration
  static const double lungeSpeed = 600.0; // Speed during lunge

  Drifter({
    required Vector2 position,
  }) : shapeType = Random().nextInt(3),
       super(
         position: position,
         width: 30,
         height: 30,
         maxHealth: 20,
         damage: 10,
         moveSpeed: 80,
         attackRange: 40,
         attackCooldown: 1.5,
         detectionRange: 300,
       ) {
    wobblePhase = Random().nextDouble() * pi * 2;
    pulsePhase = Random().nextDouble() * pi * 2;
  }

  @override
  void updateAI(double dt) {
    // Update visual phases
    wobblePhase += wobbleSpeed * dt;
    pulsePhase += 4.0 * dt;

    switch (state) {
      case EnemyState.idle:
        _idleBehavior(dt);
        break;
      case EnemyState.patrol:
        _patrolBehavior(dt);
        break;
      case EnemyState.chase:
        _chaseBehavior(dt);
        break;
      case EnemyState.attackWindup:
        _attackWindupBehavior(dt);
        break;
      case EnemyState.attackLunge:
        _attackLungeBehavior(dt);
        break;
      default:
        break;
    }
  }

  void _idleBehavior(double dt) {
    // Gentle floating
    velocity.y = sin(wobblePhase) * wobbleAmount * 0.3;

    // Check if player is visible
    if (targetPosition != null && canSeePlayer(targetPosition!)) {
      state = EnemyState.chase;
    } else {
      // Randomly start patrolling
      patrolTimer += dt;
      if (patrolTimer > 2.0) {
        patrolTimer = 0;
        state = EnemyState.patrol;
        patrolDirection = Random().nextBool() ? 1 : -1;
      }
    }
  }

  void _patrolBehavior(double dt) {
    // Drift in patrol direction with wobble
    velocity.x = patrolDirection * moveSpeed * 0.5;
    velocity.y = sin(wobblePhase) * wobbleAmount;

    patrolTimer += dt;
    if (patrolTimer > 3.0) {
      patrolTimer = 0;
      state = EnemyState.idle;
    }

    // Check if player is visible
    if (targetPosition != null && canSeePlayer(targetPosition!)) {
      state = EnemyState.chase;
    }
  }

  void _chaseBehavior(double dt) {
    if (targetPosition == null) {
      state = EnemyState.idle;
      return;
    }

    // Check for blocking platforms and navigate around them
    final blocker = getBlockingPlatform(targetPosition!);
    final Vector2 moveDirection;

    if (blocker != null) {
      // There's a platform in the way - steer around it
      moveDirection = getSteeringDirection(targetPosition!, blocker);
    } else {
      // Direct path is clear - move toward player
      final direction = targetPosition! - position;
      if (direction.length > 1) {
        moveDirection = direction.normalized();
      } else {
        moveDirection = Vector2.zero();
      }
    }

    // Apply movement
    velocity.x = moveDirection.x * moveSpeed;
    velocity.y = moveDirection.y * moveSpeed * 0.5 + sin(wobblePhase) * wobbleAmount;

    // Check if can attack - start wind-up
    if (canAttackPlayer(targetPosition!) && attackTimer <= 0) {
      state = EnemyState.attackWindup;
      windupTimer = windupDuration;
      // Store direction to player for the lunge
      lungeDirection = (targetPosition! - position).normalized();
    }

    // Lose interest if player is too far
    if (!canSeePlayer(targetPosition!)) {
      state = EnemyState.idle;
    }
  }

  void _attackWindupBehavior(double dt) {
    // Slow down and "charge up" before lunging
    velocity.x *= 0.8;
    velocity.y = sin(wobblePhase) * wobbleAmount * 0.5;

    // Update lunge direction to track player during wind-up
    if (targetPosition != null) {
      lungeDirection = (targetPosition! - position).normalized();
    }

    windupTimer -= dt;
    if (windupTimer <= 0) {
      // Transition to lunge
      state = EnemyState.attackLunge;
      lungeTimer = lungeDuration;
      isLunging = true;
      // Apply fast lunge velocity
      velocity.x = lungeDirection.x * lungeSpeed;
      velocity.y = lungeDirection.y * lungeSpeed;
    }
  }

  void _attackLungeBehavior(double dt) {
    // Maintain lunge velocity (slight drag)
    velocity.x *= 0.95;
    velocity.y *= 0.95;

    lungeTimer -= dt;
    if (lungeTimer <= 0) {
      // Attack finished
      isLunging = false;
      attackTimer = attackCooldown;
      state = EnemyState.chase;
    }
  }

  @override
  void performAttack() {
    // Attack is handled by collision in combat system
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Drifters float - slightly reduced gravity (they still fall, just slower)
    if (!isDead) {
      velocity.y -= 300 * dt; // Counter some gravity for floaty feel
    }
  }

  @override
  List<PickupType> getDrops() {
    // 80% chance for energy, 20% chance for coin
    if (Random().nextDouble() < 0.8) {
      return [PickupType.energy];
    } else {
      return [PickupType.coin];
    }
  }
}
