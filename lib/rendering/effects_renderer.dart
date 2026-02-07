import 'dart:math';

import 'package:flutter/material.dart';

import '../combat/damage_numbers.dart';
import '../combat/particle_system.dart';
import '../entities/pickup.dart';
import '../entities/enemy.dart';
import '../utils/math_utils.dart';

class EffectsRenderer {
  void renderParticles(
      Canvas canvas, ParticleSystem particles, Vector2 cameraOffset) {
    for (final particle in particles.particles) {
      final screenX = particle.position.x - cameraOffset.x;
      final screenY = particle.position.y - cameraOffset.y;

      canvas.save();
      canvas.translate(screenX, screenY);
      canvas.rotate(particle.rotation);

      final paint = Paint()
        ..color = particle.color.withValues(alpha: particle.opacity);

      switch (particle.type) {
        case ParticleType.spark:
        case ParticleType.hit:
          // Draw as small diamond
          final path = Path();
          path.moveTo(0, -particle.size);
          path.lineTo(particle.size * 0.5, 0);
          path.lineTo(0, particle.size);
          path.lineTo(-particle.size * 0.5, 0);
          path.close();
          canvas.drawPath(path, paint);
          break;

        case ParticleType.death:
          // Draw as square
          canvas.drawRect(
            Rect.fromCenter(
              center: Offset.zero,
              width: particle.size,
              height: particle.size,
            ),
            paint,
          );
          break;

        case ParticleType.dash:
          // Draw as circle with glow
          paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
          canvas.drawCircle(Offset.zero, particle.size, paint);
          break;

        case ParticleType.heal:
        case ParticleType.energy:
          // Draw as small circle
          canvas.drawCircle(Offset.zero, particle.size, paint);
          break;
      }

      canvas.restore();
    }
  }

  void renderDamageNumbers(
      Canvas canvas, DamageNumberManager manager, Vector2 cameraOffset) {
    for (final number in manager.numbers) {
      final screenX = number.position.x - cameraOffset.x;
      final screenY = number.position.y - cameraOffset.y;

      final textPainter = TextPainter(
        text: TextSpan(
          text: number.displayText,
          style: TextStyle(
            color: number.color.withValues(alpha: number.opacity),
            fontSize: 16 * number.scale,
            fontWeight: number.isCritical ? FontWeight.bold : FontWeight.normal,
            fontFamily: 'monospace',
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: number.opacity * 0.8),
                offset: const Offset(1, 1),
                blurRadius: 2,
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(screenX - textPainter.width / 2, screenY - textPainter.height / 2),
      );
    }
  }

  void renderPickups(Canvas canvas, List<Pickup> pickups, Vector2 cameraOffset) {
    for (final pickup in pickups) {
      if (pickup.collected || pickup.isBlinking) continue;

      final screenX = pickup.position.x - cameraOffset.x;
      final screenY = pickup.position.y - cameraOffset.y + pickup.bobOffset;

      final size = pickup.width * pickup.pulseScale;

      // Get color based on type
      final Color color;
      final Color glowColor;
      switch (pickup.type) {
        case PickupType.health:
          color = const Color(0xFF00FF88);
          glowColor = const Color(0xFF00FF88);
          break;
        case PickupType.energy:
          color = const Color(0xFF00AAFF);
          glowColor = const Color(0xFF00AAFF);
          break;
        case PickupType.coin:
          color = const Color(0xFFFFDD00);
          glowColor = const Color(0xFFFFDD00);
          break;
        case PickupType.essence:
          color = const Color(0xFFAA00FF);
          glowColor = const Color(0xFFAA00FF);
          break;
      }

      // Glow
      final glowPaint = Paint()
        ..color = glowColor.withValues(alpha: 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(Offset(screenX, screenY), size, glowPaint);

      // Main pickup
      final paint = Paint()..color = color;

      // Draw shape based on type
      switch (pickup.type) {
        case PickupType.health:
          // Draw plus/cross
          final thickness = size / 3;
          canvas.drawRect(
            Rect.fromCenter(
              center: Offset(screenX, screenY),
              width: thickness,
              height: size,
            ),
            paint,
          );
          canvas.drawRect(
            Rect.fromCenter(
              center: Offset(screenX, screenY),
              width: size,
              height: thickness,
            ),
            paint,
          );
          break;

        case PickupType.energy:
          // Draw diamond
          final path = Path();
          path.moveTo(screenX, screenY - size / 2);
          path.lineTo(screenX + size / 2, screenY);
          path.lineTo(screenX, screenY + size / 2);
          path.lineTo(screenX - size / 2, screenY);
          path.close();
          canvas.drawPath(path, paint);
          break;

        case PickupType.coin:
          // Draw circle
          canvas.drawCircle(Offset(screenX, screenY), size / 2, paint);
          // Inner highlight
          canvas.drawCircle(
            Offset(screenX - size / 6, screenY - size / 6),
            size / 4,
            Paint()..color = const Color(0xFFFFFFAA),
          );
          break;

        case PickupType.essence:
          // Draw star shape
          _drawStar(canvas, screenX, screenY, size / 2, 5, paint);
          break;
      }
    }
  }

  void _drawStar(Canvas canvas, double cx, double cy, double radius,
      int points, Paint paint) {
    final path = Path();
    final innerRadius = radius * 0.5;

    for (var i = 0; i < points * 2; i++) {
      final angle = (i / (points * 2)) * pi * 2 - pi / 2;
      final r = i.isEven ? radius : innerRadius;
      final x = cx + cos(angle) * r;
      final y = cy + sin(angle) * r;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }
}
