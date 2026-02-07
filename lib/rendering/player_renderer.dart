import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../data/constants.dart';
import '../entities/player.dart';
import '../utils/math_utils.dart';

class PlayerRenderer {
  void render(Canvas canvas, Player player, Vector2 cameraOffset) {
    final screenX = player.position.x - cameraOffset.x;
    final screenY = player.position.y - cameraOffset.y;

    // Draw attack arc (behind player)
    if (player.isAttacking) {
      _drawAttackArc(canvas, screenX, screenY, player);
    }

    // Draw afterimages first (behind player)
    for (final afterimage in player.afterimages) {
      _drawPlayerShape(
        canvas,
        afterimage.position.x - cameraOffset.x,
        afterimage.position.y - cameraOffset.y,
        player.width,
        player.height,
        afterimage.facingRight,
        afterimage.opacity,
        isAfterimage: true,
      );
    }

    // Draw main player
    _drawPlayerShape(
      canvas,
      screenX,
      screenY,
      player.width,
      player.height,
      player.facingRight,
      1.0,
      state: player.state,
      isDashing: player.isDashing,
      isHitFlashing: player.hitFlashTimer > 0,
    );

    // Draw debug hitbox (optional)
    // _drawHitbox(canvas, player, cameraOffset);
  }

  void _drawAttackArc(Canvas canvas, double x, double y, Player player) {
    final progress = 1.0 - (player.attackTimer / Player.attackDuration);
    final arcAngle = player.attackAngle;

    // Arc sweep from -60 to +60 degrees relative to attack direction (wider arc)
    final sweepStart = arcAngle - pi / 3;
    final sweepAngle = (2 * pi / 3) * progress;

    // Outer flash burst (bright white flash at start)
    if (progress < 0.5) {
      final flashAlpha = (1.0 - progress * 2).clamp(0.0, 1.0);
      final flashPaint = Paint()
        ..color = Colors.white.withValues(alpha: flashAlpha * 0.8)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
      canvas.drawCircle(
        Offset(x + cos(arcAngle) * 40, y + sin(arcAngle) * 40),
        50 * (1 - progress),
        flashPaint,
      );
    }

    // Main slash trail (thick, bright)
    final slashPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9 * (1 - progress * 0.5))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8 + (1 - progress) * 6 // Thicker at start
      ..strokeCap = StrokeCap.round;

    final slashRect = Rect.fromCenter(
      center: Offset(x, y),
      width: 160, // Bigger arc
      height: 160,
    );

    canvas.drawArc(slashRect, sweepStart, sweepAngle, false, slashPaint);

    // Bright core of slash
    final corePaint = Paint()
      ..color = const Color(0xFFFFFFFF).withValues(alpha: (1 - progress))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(slashRect, sweepStart, sweepAngle, false, corePaint);

    // Outer glow (colored)
    final glowPaint = Paint()
      ..color = playerGlowColor.withValues(alpha: 0.6 * (1 - progress))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    canvas.drawArc(slashRect, sweepStart, sweepAngle, false, glowPaint);

    // Speed lines emanating from slash direction
    if (progress < 0.7) {
      final lineAlpha = (1.0 - progress / 0.7).clamp(0.0, 1.0);
      final linePaint = Paint()
        ..color = Colors.white.withValues(alpha: lineAlpha * 0.6)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;

      for (var i = 0; i < 5; i++) {
        final lineAngle = arcAngle + (i - 2) * 0.15;
        final startDist = 50 + progress * 30;
        final endDist = 80 + progress * 50;
        canvas.drawLine(
          Offset(x + cos(lineAngle) * startDist, y + sin(lineAngle) * startDist),
          Offset(x + cos(lineAngle) * endDist, y + sin(lineAngle) * endDist),
          linePaint,
        );
      }
    }
  }

  void _drawPlayerShape(
    Canvas canvas,
    double x,
    double y,
    double width,
    double height,
    bool facingRight,
    double opacity, {
    bool isAfterimage = false,
    PlayerState state = PlayerState.idle,
    bool isDashing = false,
    bool isHitFlashing = false,
  }) {
    final baseColor = isHitFlashing
        ? Colors.white.withValues(alpha: opacity)
        : playerColor.withValues(alpha: opacity);
    final glowColor = isHitFlashing
        ? Colors.red.withValues(alpha: opacity * 0.8)
        : playerGlowColor.withValues(alpha: opacity * 0.5);

    // Stretch effect during dash
    double scaleX = 1.0;
    double scaleY = 1.0;
    if (isDashing && !isAfterimage) {
      scaleX = 1.4;
      scaleY = 0.7;
    }

    final w = width * scaleX;
    final h = height * scaleY;

    // Create diamond path
    final path = Path();
    path.moveTo(x, y - h / 2); // Top
    path.lineTo(x + w / 2, y); // Right
    path.lineTo(x, y + h / 2); // Bottom
    path.lineTo(x - w / 2, y); // Left
    path.close();

    // Draw glow layer
    final glowPaint = Paint()
      ..color = glowColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawPath(path, glowPaint);

    // Draw solid fill
    final fillPaint = Paint()
      ..color = baseColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // Draw bright edge
    final edgePaint = Paint()
      ..color = Colors.white.withValues(alpha: opacity * 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(path, edgePaint);

    // Draw inner core (brighter center)
    if (!isAfterimage) {
      final coreSize = w * 0.3;
      final corePath = Path();
      corePath.moveTo(x, y - coreSize / 2);
      corePath.lineTo(x + coreSize / 2, y);
      corePath.lineTo(x, y + coreSize / 2);
      corePath.lineTo(x - coreSize / 2, y);
      corePath.close();

      final corePaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.9)
        ..style = PaintingStyle.fill;
      canvas.drawPath(corePath, corePaint);
    }

    // Draw direction indicator (arrow pointing in facing direction)
    if (!isAfterimage) {
      final indicatorSize = 12.0;
      final indicatorOffset = 8.0;
      final indicatorX = facingRight ? x + w / 2 + indicatorOffset : x - w / 2 - indicatorOffset;
      final indicatorPath = Path();

      if (facingRight) {
        indicatorPath.moveTo(indicatorX + indicatorSize / 2, y);
        indicatorPath.lineTo(indicatorX - indicatorSize / 2, y - indicatorSize / 2);
        indicatorPath.lineTo(indicatorX - indicatorSize / 4, y);
        indicatorPath.lineTo(indicatorX - indicatorSize / 2, y + indicatorSize / 2);
      } else {
        indicatorPath.moveTo(indicatorX - indicatorSize / 2, y);
        indicatorPath.lineTo(indicatorX + indicatorSize / 2, y - indicatorSize / 2);
        indicatorPath.lineTo(indicatorX + indicatorSize / 4, y);
        indicatorPath.lineTo(indicatorX + indicatorSize / 2, y + indicatorSize / 2);
      }
      indicatorPath.close();

      // Glow for indicator
      final indicatorGlowPaint = Paint()
        ..color = glowColor
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawPath(indicatorPath, indicatorGlowPaint);

      // Solid indicator
      final indicatorPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.9)
        ..style = PaintingStyle.fill;
      canvas.drawPath(indicatorPath, indicatorPaint);
    }

    // Wall slide indicator (lines on the side)
    if (state == PlayerState.wallSliding && !isAfterimage) {
      final linePaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.6)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;

      final wallSide = facingRight ? 1 : -1;
      for (var i = 0; i < 3; i++) {
        final lineY = y - 10 + i * 10;
        canvas.drawLine(
          Offset(x + wallSide * (w / 2 + 2), lineY.toDouble()),
          Offset(x + wallSide * (w / 2 + 8), lineY - 5),
          linePaint,
        );
      }
    }
  }

  void _drawHitbox(Canvas canvas, Player player, Vector2 cameraOffset) {
    final hitboxPaint = Paint()
      ..color = Colors.red.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final hitbox = player.hitbox.translate(-cameraOffset.x, -cameraOffset.y);
    canvas.drawRect(hitbox, hitboxPaint);

    // Feet sensor
    final feetPaint = Paint()
      ..color = Colors.green.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;
    final feetRect = player.feetRect.translate(-cameraOffset.x, -cameraOffset.y);
    canvas.drawRect(feetRect, feetPaint);

    // Wall sensors
    final wallPaint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;
    final leftRect = player.leftRect.translate(-cameraOffset.x, -cameraOffset.y);
    final rightRect = player.rightRect.translate(-cameraOffset.x, -cameraOffset.y);
    canvas.drawRect(leftRect, wallPaint);
    canvas.drawRect(rightRect, wallPaint);
  }
}
