import 'dart:math';

import 'package:flutter/material.dart';

import '../entities/drifter.dart';
import '../entities/enemy.dart';
import '../utils/math_utils.dart';

class EnemyRenderer {
  void render(Canvas canvas, List<Enemy> enemies, Vector2 cameraOffset) {
    for (final enemy in enemies) {
      if (enemy is Drifter) {
        _renderDrifter(canvas, enemy, cameraOffset);
      }
    }
  }

  void _renderDrifter(Canvas canvas, Drifter drifter, Vector2 cameraOffset) {
    final screenX = drifter.position.x - cameraOffset.x;
    final screenY = drifter.position.y - cameraOffset.y;

    // Don't render if dead and death animation complete
    if (drifter.isDead && drifter.deathTimer <= 0) return;

    // Check attack states
    final isWindingUp = drifter.state == EnemyState.attackWindup;
    final isLunging = drifter.state == EnemyState.attackLunge;

    canvas.save();
    canvas.translate(screenX, screenY);

    // Death animation - shrink and fade
    double scale = 1.0;
    double opacity = 1.0;
    if (drifter.isDead) {
      scale = drifter.deathTimer / 0.5;
      opacity = scale;
    }

    // Hit flash
    final isFlashing = drifter.hitFlashTimer > 0;

    // Pulse animation - faster and bigger during wind-up
    double pulseScale;
    if (isWindingUp) {
      // Rapid pulsing during wind-up (warning!)
      pulseScale = 1.0 + sin(drifter.pulsePhase * 4) * 0.2;
    } else {
      pulseScale = 1.0 + sin(drifter.pulsePhase) * 0.1;
    }
    scale *= pulseScale;

    // Stretch during lunge
    double stretchX = 1.0;
    double stretchY = 1.0;
    if (isLunging) {
      stretchX = 1.5;
      stretchY = 0.6;
    }

    // Wobble rotation
    final wobbleRotation = sin(drifter.wobblePhase) * 0.1;
    canvas.rotate(wobbleRotation);

    final size = drifter.width * scale;

    // Determine glow color based on state
    Color glowColor;
    double blurRadius = 12.0;
    if (isFlashing) {
      glowColor = Colors.white.withValues(alpha: 0.8 * opacity);
    } else if (isWindingUp) {
      // Red warning glow during wind-up
      glowColor = const Color(0xFFFF0000).withValues(alpha: 0.8 * opacity);
      blurRadius = 20.0;
    } else if (isLunging) {
      // Bright orange during lunge
      glowColor = const Color(0xFFFFAA00).withValues(alpha: 0.9 * opacity);
      blurRadius = 16.0;
    } else {
      glowColor = const Color(0xFFFF6600).withValues(alpha: 0.4 * opacity);
    }

    final glowPaint = Paint()
      ..color = glowColor
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blurRadius);

    // Apply stretch for lunge
    canvas.scale(stretchX, stretchY);

    _drawShape(canvas, drifter.shapeType, size * 1.3, glowPaint);

    // Main body - color changes based on state
    Color bodyColor;
    if (isFlashing) {
      bodyColor = Colors.white;
    } else if (isWindingUp) {
      bodyColor = const Color(0xFFFF2200).withValues(alpha: opacity); // Red during wind-up
    } else if (isLunging) {
      bodyColor = const Color(0xFFFFCC00).withValues(alpha: opacity); // Bright yellow during lunge
    } else {
      bodyColor = const Color(0xFFFF6600).withValues(alpha: opacity);
    }
    final bodyPaint = Paint()
      ..color = bodyColor
      ..style = PaintingStyle.fill;

    _drawShape(canvas, drifter.shapeType, size, bodyPaint);

    // Inner highlight
    Color innerColor;
    if (isFlashing) {
      innerColor = Colors.white;
    } else if (isWindingUp || isLunging) {
      innerColor = Colors.white.withValues(alpha: 0.8 * opacity);
    } else {
      innerColor = const Color(0xFFFFAA44).withValues(alpha: 0.6 * opacity);
    }
    final innerPaint = Paint()
      ..color = innerColor
      ..style = PaintingStyle.fill;

    _drawShape(canvas, drifter.shapeType, size * 0.5, innerPaint);

    // Eye/core
    final corePaint = Paint()
      ..color = Colors.white.withValues(alpha: opacity)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset.zero, size * 0.15, corePaint);

    canvas.restore();

    // Health bar (if damaged)
    if (drifter.health < drifter.maxHealth && !drifter.isDead) {
      _renderHealthBar(canvas, drifter, screenX, screenY);
    }
  }

  void _drawShape(Canvas canvas, int shapeType, double size, Paint paint) {
    switch (shapeType) {
      case 0: // Triangle
        final path = Path();
        for (var i = 0; i < 3; i++) {
          final angle = (i / 3) * pi * 2 - pi / 2;
          final x = cos(angle) * size / 2;
          final y = sin(angle) * size / 2;
          if (i == 0) {
            path.moveTo(x, y);
          } else {
            path.lineTo(x, y);
          }
        }
        path.close();
        canvas.drawPath(path, paint);
        break;

      case 1: // Square (diamond orientation)
        canvas.save();
        canvas.rotate(pi / 4);
        canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: size * 0.7, height: size * 0.7),
          paint,
        );
        canvas.restore();
        break;

      case 2: // Pentagon
        final path = Path();
        for (var i = 0; i < 5; i++) {
          final angle = (i / 5) * pi * 2 - pi / 2;
          final x = cos(angle) * size / 2;
          final y = sin(angle) * size / 2;
          if (i == 0) {
            path.moveTo(x, y);
          } else {
            path.lineTo(x, y);
          }
        }
        path.close();
        canvas.drawPath(path, paint);
        break;
    }
  }

  void _renderHealthBar(
      Canvas canvas, Enemy enemy, double screenX, double screenY) {
    final barWidth = enemy.width;
    final barHeight = 4.0;
    final barY = screenY - enemy.height / 2 - 10;

    // Background
    final bgRect = Rect.fromLTWH(
      screenX - barWidth / 2,
      barY,
      barWidth,
      barHeight,
    );
    canvas.drawRect(bgRect, Paint()..color = Colors.black54);

    // Health fill
    final healthRatio = enemy.health / enemy.maxHealth;
    final healthRect = Rect.fromLTWH(
      screenX - barWidth / 2,
      barY,
      barWidth * healthRatio,
      barHeight,
    );

    final healthColor = healthRatio > 0.5
        ? Colors.greenAccent
        : healthRatio > 0.25
            ? Colors.orange
            : Colors.red;

    canvas.drawRect(healthRect, Paint()..color = healthColor);
  }
}
