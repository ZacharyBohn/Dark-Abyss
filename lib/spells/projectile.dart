import 'dart:math';
import 'dart:ui';

import '../combat/particle_system.dart';
import '../entities/enemy.dart';
import '../utils/math_utils.dart';

enum ProjectileType {
  fireball,
  ice,
  lightning,
}

class Projectile {
  Vector2 position;
  Vector2 velocity;
  double damage;
  double lifetime;
  double maxLifetime;
  bool isDead = false;
  ProjectileType type;
  double radius;

  // Visual properties
  Color color;
  double trailTimer = 0;

  // Hit tracking (to prevent multiple hits on same enemy)
  Set<Enemy> hitEnemies = {};

  Projectile({
    required this.position,
    required this.velocity,
    required this.damage,
    required this.maxLifetime,
    required this.type,
    this.radius = 8.0,
    this.color = const Color(0xFFFF6600),
  }) : lifetime = maxLifetime;

  void update(double dt) {
    position.x += velocity.x * dt;
    position.y += velocity.y * dt;

    lifetime -= dt;
    if (lifetime <= 0) {
      isDead = true;
    }

    trailTimer += dt;
  }

  /// Check collision with enemy
  bool checkCollision(Enemy enemy) {
    if (hitEnemies.contains(enemy)) return false;

    final dx = position.x - enemy.position.x;
    final dy = position.y - enemy.position.y;
    final distance = (dx * dx + dy * dy);
    final collisionDist = radius + enemy.width / 2;

    return distance < collisionDist * collisionDist;
  }

  /// Mark enemy as hit
  void markHit(Enemy enemy) {
    hitEnemies.add(enemy);
  }

  /// Get the rect for bounds checking
  Rect get bounds => Rect.fromCenter(
        center: Offset(position.x, position.y),
        width: radius * 2,
        height: radius * 2,
      );

  /// Create impact particles
  List<Particle> createImpactParticles() {
    final particles = <Particle>[];
    final particleCount = type == ProjectileType.fireball ? 12 : 8;

    for (var i = 0; i < particleCount; i++) {
      final angle = (i / particleCount) * 3.14159 * 2;
      final speed = 100.0 + (i % 3) * 50.0;
      particles.add(Particle(
        position: position.copy(),
        velocity: Vector2(
          cos(angle) * speed,
          sin(angle) * speed,
        ),
        lifetime: 0.3 + (i % 2) * 0.2,
        color: color,
        size: 3.0,
        type: ParticleType.hit,
      ));
    }

    return particles;
  }
}
