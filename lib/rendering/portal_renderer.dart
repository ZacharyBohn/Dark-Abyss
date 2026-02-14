import 'dart:math';

import 'package:flutter/material.dart';

import '../dungeon/exit_portal.dart';
import '../utils/math_utils.dart';

class PortalRenderer {
  void render(
    Canvas canvas,
    ExitPortal? portal,
    Vector2 cameraOffset, {
    Color? colorOverride,
  }) {
    if (portal == null) return;

    final screenX = portal.position.x - cameraOffset.x;
    final screenY = portal.position.y - cameraOffset.y;
    final radius = portal.radius * portal.pulseScale;

    // Determine color based on state
    final Color baseColor;
    final Color glowColor;
    if (portal.isUnlocked) {
      baseColor = colorOverride ?? const Color(0xFF00FF88);
      glowColor = colorOverride ?? const Color(0xFF00FF88);
    } else {
      baseColor = const Color(0xFF666666);
      glowColor = const Color(0xFF444444);
    }

    canvas.save();
    canvas.translate(screenX, screenY);
    canvas.rotate(portal.rotationAngle);

    // Outer glow
    final outerGlowPaint = Paint()
      ..color = glowColor.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawCircle(Offset.zero, radius * 1.5, outerGlowPaint);

    // Inner glow
    final innerGlowPaint = Paint()
      ..color = glowColor.withValues(alpha: 0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(Offset.zero, radius, innerGlowPaint);

    // Portal ring
    final ringPaint = Paint()
      ..color = baseColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(Offset.zero, radius, ringPaint);

    // Inner ring
    final innerRingPaint = Paint()
      ..color = baseColor.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(Offset.zero, radius * 0.7, innerRingPaint);

    // Rotating spokes (only when unlocked)
    if (portal.isUnlocked) {
      final spokePaint = Paint()
        ..color = baseColor.withValues(alpha: 0.8)
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke;

      for (int i = 0; i < 6; i++) {
        final angle = (i / 6) * pi * 2;
        final innerPoint = Offset(cos(angle) * radius * 0.3, sin(angle) * radius * 0.3);
        final outerPoint = Offset(cos(angle) * radius * 0.85, sin(angle) * radius * 0.85);
        canvas.drawLine(innerPoint, outerPoint, spokePaint);
      }

      // Center glow
      final centerPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.9)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
      canvas.drawCircle(Offset.zero, radius * 0.2, centerPaint);
    } else {
      // Lock symbol when not unlocked
      final lockPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      // Draw X
      canvas.drawLine(
        Offset(-radius * 0.3, -radius * 0.3),
        Offset(radius * 0.3, radius * 0.3),
        lockPaint,
      );
      canvas.drawLine(
        Offset(radius * 0.3, -radius * 0.3),
        Offset(-radius * 0.3, radius * 0.3),
        lockPaint,
      );
    }

    canvas.restore();

    // Draw "CLEAR" or enemy count text above portal
    if (!portal.isUnlocked) {
      // Will be handled by HUD
    }
  }
}
