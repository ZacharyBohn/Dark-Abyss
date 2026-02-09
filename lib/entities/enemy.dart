import 'dart:ui';

import '../dungeon/platform.dart';
import '../economy/loot_table.dart';
import '../utils/math_utils.dart';
import 'entity.dart';

enum EnemyState {
  idle,
  patrol,
  chase,
  attackWindup,
  attackLunge,
  hit,
  dying,
}

abstract class Enemy extends Entity {
  EnemyState state = EnemyState.idle;

  // Stats
  double maxHealth;
  double health;
  double damage;
  double moveSpeed;
  double attackRange;
  double attackCooldown;
  double detectionRange;

  // Timers
  double attackTimer = 0;
  double hitStunTimer = 0;
  double deathTimer = 0;

  // State
  bool facingRight = true;
  bool isDead = false;
  double hitFlashTimer = 0;
  bool isLunging = false; // True during attack lunge phase (when damage can be dealt)

  // AI
  Vector2? targetPosition;
  double patrolTimer = 0;
  double patrolDirection = 1;

  // Pathfinding
  List<Platform> platforms = [];

  // Floor tracking for loot scaling
  int currentFloor = 1;

  Enemy({
    required Vector2 position,
    required double width,
    required double height,
    required this.maxHealth,
    required this.damage,
    required this.moveSpeed,
    required this.attackRange,
    required this.attackCooldown,
    required this.detectionRange,
  }) : health = maxHealth,
       super(position: position, width: width, height: height);

  void takeDamage(double amount, {Vector2? knockbackDirection}) {
    if (isDead) return;

    health -= amount;
    hitFlashTimer = 0.1;
    hitStunTimer = 0.2;
    state = EnemyState.hit;

    // Apply knockback
    if (knockbackDirection != null) {
      velocity.x = knockbackDirection.x * 300;
      velocity.y = knockbackDirection.y * 150 - 100;
    }

    if (health <= 0) {
      health = 0;
      die();
    }
  }

  void die() {
    isDead = true;
    state = EnemyState.dying;
    deathTimer = 0.5;
    velocity = Vector2.zero();
  }

  @override
  void update(double dt) {
    if (isDead) {
      deathTimer -= dt;
      return;
    }

    // Update timers
    if (hitFlashTimer > 0) hitFlashTimer -= dt;
    if (hitStunTimer > 0) hitStunTimer -= dt;
    if (attackTimer > 0) attackTimer -= dt;

    // Don't process AI while stunned
    if (hitStunTimer > 0) {
      // Just apply physics
      _applyPhysics(dt);
      return;
    }

    // AI behavior (implemented by subclasses)
    updateAI(dt);

    // Apply physics
    _applyPhysics(dt);

    // Update facing direction
    if (velocity.x > 0.1) facingRight = true;
    if (velocity.x < -0.1) facingRight = false;
  }

  void _applyPhysics(double dt) {
    // Gravity
    velocity.y += 800 * dt;

    // Friction
    velocity.x *= 0.9;

    // Apply velocity
    position.x += velocity.x * dt;
    position.y += velocity.y * dt;
  }

  // Override in subclasses for specific AI behavior
  void updateAI(double dt);

  // Override to define attack behavior
  void performAttack();

  // Check if player is in detection range
  bool canSeePlayer(Vector2 playerPos) {
    return position.distanceTo(playerPos) < detectionRange;
  }

  // Check if player is in attack range
  bool canAttackPlayer(Vector2 playerPos) {
    return position.distanceTo(playerPos) < attackRange;
  }

  /// Check if there's a platform blocking the direct path to target
  Platform? getBlockingPlatform(Vector2 target) {
    // Simple ray cast check - see if any platform intersects the line
    final direction = target - position;
    final distance = direction.length;
    if (distance < 1) return null;

    // Check platforms for intersection
    for (final platform in platforms) {
      // Skip very thin platforms (floors) - we can fly over them
      if (platform.height < 30 && !platform.isWall) continue;

      // Expand platform rect slightly to account for enemy size
      final expandedRect = Rect.fromLTRB(
        platform.left - width / 2,
        platform.top - height / 2,
        platform.right + width / 2,
        platform.bottom + height / 2,
      );

      // Check if the line from position to target intersects this platform
      if (_lineIntersectsRect(position, target, expandedRect)) {
        return platform;
      }
    }
    return null;
  }

  /// Simple line-rect intersection check
  bool _lineIntersectsRect(Vector2 start, Vector2 end, Rect rect) {
    // Check if either endpoint is inside the rect
    if (rect.contains(Offset(start.x, start.y))) return true;
    if (rect.contains(Offset(end.x, end.y))) return true;

    // Check if line crosses any edge
    final lines = [
      [Vector2(rect.left, rect.top), Vector2(rect.right, rect.top)],
      [Vector2(rect.right, rect.top), Vector2(rect.right, rect.bottom)],
      [Vector2(rect.right, rect.bottom), Vector2(rect.left, rect.bottom)],
      [Vector2(rect.left, rect.bottom), Vector2(rect.left, rect.top)],
    ];

    for (final line in lines) {
      if (_linesIntersect(start, end, line[0], line[1])) {
        return true;
      }
    }
    return false;
  }

  /// Check if two line segments intersect
  bool _linesIntersect(Vector2 a1, Vector2 a2, Vector2 b1, Vector2 b2) {
    final d1 = _cross(b2 - b1, a1 - b1);
    final d2 = _cross(b2 - b1, a2 - b1);
    final d3 = _cross(a2 - a1, b1 - a1);
    final d4 = _cross(a2 - a1, b2 - a1);

    if (((d1 > 0 && d2 < 0) || (d1 < 0 && d2 > 0)) &&
        ((d3 > 0 && d4 < 0) || (d3 < 0 && d4 > 0))) {
      return true;
    }
    return false;
  }

  double _cross(Vector2 a, Vector2 b) => a.x * b.y - a.y * b.x;

  /// Get a navigation direction that steers around a blocking platform
  Vector2 getSteeringDirection(Vector2 target, Platform blocker) {
    final toTarget = target - position;

    // Determine if we should go up/down or left/right around the platform
    final platformCenter = Vector2(
      blocker.x + blocker.width / 2,
      blocker.y + blocker.height / 2,
    );

    // Calculate waypoints around the platform
    final goingRight = target.x > position.x;
    final goingDown = target.y > position.y;

    // Choose the corner that gets us around the obstacle fastest
    Vector2 waypoint;

    if (blocker.isWall || blocker.height > blocker.width) {
      // Tall obstacle - go over or under
      if (goingDown) {
        // Target is below, go under the platform
        waypoint = Vector2(platformCenter.x, blocker.bottom + height);
      } else {
        // Target is above, go over the platform
        waypoint = Vector2(platformCenter.x, blocker.top - height);
      }
    } else {
      // Wide obstacle - go around the side
      if (goingRight) {
        // Going right, check if going over is faster
        if (position.y < platformCenter.y) {
          waypoint = Vector2(platformCenter.x, blocker.top - height);
        } else {
          waypoint = Vector2(blocker.right + width, platformCenter.y);
        }
      } else {
        // Going left
        if (position.y < platformCenter.y) {
          waypoint = Vector2(platformCenter.x, blocker.top - height);
        } else {
          waypoint = Vector2(blocker.left - width, platformCenter.y);
        }
      }
    }

    // Return direction to waypoint
    final toWaypoint = waypoint - position;
    if (toWaypoint.length > 1) {
      return toWaypoint.normalized();
    }
    return toTarget.normalized();
  }

  // Get drops when killed (override in subclasses)
  List<DropInfo> getDrops() => [];
}

enum PickupType {
  health,
  energy,
  coin,
  essence,
}
