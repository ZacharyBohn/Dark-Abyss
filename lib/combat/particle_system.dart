import 'dart:math';
import 'dart:ui';

import '../utils/math_utils.dart';

enum ParticleType {
  spark,
  hit,
  death,
  dash,
  heal,
  energy,
}

class Particle {
  Vector2 position;
  Vector2 velocity;
  Color color;
  double size;
  double lifetime;
  double maxLifetime;
  ParticleType type;

  // Animation
  double rotation = 0;
  double rotationSpeed;

  Particle({
    required this.position,
    required this.velocity,
    required this.color,
    required this.size,
    required this.lifetime,
    required this.type,
  }) : maxLifetime = lifetime,
       rotationSpeed = (Random().nextDouble() - 0.5) * 10;

  void update(double dt) {
    lifetime -= dt;

    // Physics
    position.x += velocity.x * dt;
    position.y += velocity.y * dt;

    // Gravity for some types
    if (type == ParticleType.spark || type == ParticleType.death) {
      velocity.y += 300 * dt;
    }

    // Friction
    velocity.x *= 0.98;
    velocity.y *= 0.98;

    // Rotation
    rotation += rotationSpeed * dt;

    // Shrink over time
    final lifeRatio = lifetime / maxLifetime;
    if (lifeRatio < 0.3) {
      size *= 0.95;
    }
  }

  bool get shouldRemove => lifetime <= 0 || size < 0.5;

  double get opacity => (lifetime / maxLifetime).clamp(0.0, 1.0);
}

class ParticleSystem {
  final List<Particle> particles = [];
  final Random _random = Random();

  void update(double dt) {
    for (var i = particles.length - 1; i >= 0; i--) {
      particles[i].update(dt);
      if (particles[i].shouldRemove) {
        particles.removeAt(i);
      }
    }
  }

  void spawnHitSparks(Vector2 position, Color color, {int count = 8}) {
    for (var i = 0; i < count; i++) {
      final angle = _random.nextDouble() * pi * 2;
      final speed = 100 + _random.nextDouble() * 200;

      particles.add(Particle(
        position: position.copy(),
        velocity: Vector2(cos(angle) * speed, sin(angle) * speed),
        color: color,
        size: 3 + _random.nextDouble() * 4,
        lifetime: 0.3 + _random.nextDouble() * 0.3,
        type: ParticleType.hit,
      ));
    }
  }

  void spawnDeathBurst(Vector2 position, Color color, {int count = 20}) {
    for (var i = 0; i < count; i++) {
      final angle = _random.nextDouble() * pi * 2;
      final speed = 150 + _random.nextDouble() * 250;

      particles.add(Particle(
        position: position.copy(),
        velocity: Vector2(cos(angle) * speed, sin(angle) * speed - 100),
        color: color,
        size: 4 + _random.nextDouble() * 6,
        lifetime: 0.5 + _random.nextDouble() * 0.5,
        type: ParticleType.death,
      ));
    }

    // Add some sparks
    spawnHitSparks(position, color, count: 12);
  }

  void spawnDashTrail(Vector2 position, Color color) {
    particles.add(Particle(
      position: position.copy(),
      velocity: Vector2(
        (_random.nextDouble() - 0.5) * 30,
        (_random.nextDouble() - 0.5) * 30,
      ),
      color: color,
      size: 6 + _random.nextDouble() * 4,
      lifetime: 0.2,
      type: ParticleType.dash,
    ));
  }

  void spawnPickupEffect(Vector2 position, Color color, {int count = 6}) {
    for (var i = 0; i < count; i++) {
      final angle = (i / count) * pi * 2;
      final speed = 50 + _random.nextDouble() * 50;

      particles.add(Particle(
        position: position.copy(),
        velocity: Vector2(cos(angle) * speed, sin(angle) * speed - 80),
        color: color,
        size: 3 + _random.nextDouble() * 3,
        lifetime: 0.4,
        type: ParticleType.energy,
      ));
    }
  }

  void clear() {
    particles.clear();
  }
}
