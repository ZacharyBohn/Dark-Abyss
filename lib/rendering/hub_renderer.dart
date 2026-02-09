import 'dart:math';

import 'package:flutter/material.dart';

import '../hub/vendor.dart';
import '../utils/math_utils.dart';

class HubRenderer {
  void render(
    Canvas canvas,
    Size size,
    List<Vendor> vendors,
    Vector2 cameraOffset,
    Vector2 playerPosition,
  ) {
    _drawTitle(canvas, cameraOffset);
    _drawSeparator(canvas, cameraOffset);

    for (final vendor in vendors) {
      _renderVendor(canvas, vendor, cameraOffset, playerPosition);
    }
  }

  void _drawTitle(Canvas canvas, Vector2 cameraOffset) {
    const hubCenterX = 400.0; // HubRoom.hubWidth / 2
    const worldY = 40.0;

    final titlePainter = TextPainter(
      text: const TextSpan(
        text: 'ABYSS RUNNER',
        style: TextStyle(
          color: Color(0xFF00FFFF),
          fontSize: 28,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
          letterSpacing: 4,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    titlePainter.layout();

    final screenX = hubCenterX - cameraOffset.x - titlePainter.width / 2;
    final screenY = worldY - cameraOffset.y;

    // Glow behind title
    final glowPaint = Paint()
      ..color = const Color(0xFF00FFFF).withValues(alpha: 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(
          hubCenterX - cameraOffset.x,
          screenY + titlePainter.height / 2,
        ),
        width: titlePainter.width + 40,
        height: titlePainter.height + 10,
      ),
      glowPaint,
    );

    titlePainter.paint(canvas, Offset(screenX, screenY));
  }

  void _drawSeparator(Canvas canvas, Vector2 cameraOffset) {
    final y = 600 * 0.78 - cameraOffset.y;
    final paint = Paint()
      ..color = const Color(0xFF00FFFF).withValues(alpha: 0.2)
      ..strokeWidth = 1;

    // Dashed-style separator with gaps
    const startX = 60.0;
    const endX = 740.0;
    const dashWidth = 12.0;
    const gapWidth = 8.0;

    var x = startX;
    while (x < endX) {
      final dashEnd = (x + dashWidth).clamp(startX, endX);
      canvas.drawLine(
        Offset(x - cameraOffset.x, y),
        Offset(dashEnd - cameraOffset.x, y),
        paint,
      );
      x += dashWidth + gapWidth;
    }
  }

  void _renderVendor(
    Canvas canvas,
    Vendor vendor,
    Vector2 cameraOffset,
    Vector2 playerPosition,
  ) {
    final screenX = vendor.position.x - cameraOffset.x;
    final screenY = vendor.position.y - cameraOffset.y;

    final bobOffset = sin(vendor.bobPhase) * 3.0;
    final pulseScale = 1.0 + sin(vendor.pulsePhase) * 0.05;

    // Color based on vendor type
    Color vendorColor;
    switch (vendor.type) {
      case VendorType.stat:
        vendorColor = const Color(0xFFFFDD00); // Gold
        break;
      case VendorType.ability:
        vendorColor = const Color(0xFFAA00FF); // Purple
        break;
      case VendorType.spell:
        vendorColor = const Color(0xFF00AAFF); // Blue
        break;
    }

    canvas.save();
    canvas.translate(screenX, screenY + bobOffset);

    // Outer glow
    final outerGlow = Paint()
      ..color = vendorColor.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(Offset.zero, 20 * pulseScale, outerGlow);

    // Hexagon shape (distinct from player diamond and enemy shapes)
    final size = 18.0 * pulseScale;
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (i / 6) * pi * 2 - pi / 2;
      final vx = cos(angle) * size;
      final vy = sin(angle) * size;
      if (i == 0) {
        path.moveTo(vx, vy);
      } else {
        path.lineTo(vx, vy);
      }
    }
    path.close();

    // Glow layer
    final glowPaint = Paint()
      ..color = vendorColor.withValues(alpha: 0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawPath(path, glowPaint);

    // Fill
    final fillPaint = Paint()
      ..color = vendorColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // Edge
    final edgePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawPath(path, edgePaint);

    // Inner core
    canvas.drawCircle(
      Offset.zero,
      size * 0.3,
      Paint()..color = Colors.white.withValues(alpha: 0.8),
    );

    canvas.restore();

    // Vendor name above
    final namePainter = TextPainter(
      text: TextSpan(
        text: vendor.name,
        style: TextStyle(
          color: vendorColor,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    namePainter.layout();
    namePainter.paint(
      canvas,
      Offset(screenX - namePainter.width / 2, screenY + bobOffset - 38),
    );

    // Interaction prompt when player is near
    if (vendor.isPlayerInRange(playerPosition)) {
      final promptPainter = TextPainter(
        text: TextSpan(
          text: 'Press E',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 12,
            fontFamily: 'monospace',
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      promptPainter.layout();
      promptPainter.paint(
        canvas,
        Offset(screenX - promptPainter.width / 2, screenY + bobOffset + 28),
      );
    }
  }
}
