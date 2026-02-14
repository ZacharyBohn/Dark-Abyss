import 'dart:math';

import 'package:flutter/painting.dart';

import '../spells/projectile.dart';
import '../utils/math_utils.dart';

class SpellRenderer {
  void renderProjectiles(Canvas canvas, List<Projectile> projectiles, Vector2 cameraOffset) {
    for (var projectile in projectiles) {
      _renderProjectile(canvas, projectile, cameraOffset);
    }
  }

  void _renderProjectile(Canvas canvas, Projectile projectile, Vector2 cameraOffset) {
    final screenX = projectile.position.x - cameraOffset.x;
    final screenY = projectile.position.y - cameraOffset.y;

    canvas.save();
    canvas.translate(screenX, screenY);

    switch (projectile.type) {
      case ProjectileType.fireball:
        _renderFireball(canvas, projectile);
        break;
      case ProjectileType.ice:
        _renderIceProjectile(canvas, projectile);
        break;
      case ProjectileType.lightning:
        _renderLightningProjectile(canvas, projectile);
        break;
    }

    canvas.restore();
  }

  void _renderFireball(Canvas canvas, Projectile projectile) {
    final lifeRatio = projectile.lifetime / projectile.maxLifetime;
    final radius = projectile.radius;

    // Draw glow
    final glowPaint = Paint()
      ..color = const Color(0xFFFF6600).withValues(alpha: 0.3 * lifeRatio)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(Offset.zero, radius * 1.5, glowPaint);

    // Draw core
    final corePaint = Paint()
      ..color = const Color(0xFFFF6600)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset.zero, radius, corePaint);

    // Draw bright center
    final centerPaint = Paint()
      ..color = const Color(0xFFFFDD00)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(-radius * 0.3, -radius * 0.3), radius * 0.5, centerPaint);

    // Draw trail particles (simple fading circles behind)
    if (projectile.trailTimer > 0.03) {
      final trailPaint = Paint()
        ..color = const Color(0xFFFF6600).withValues(alpha: 0.4)
        ..style = PaintingStyle.fill;
      final trailDir = Vector2(-projectile.velocity.x, -projectile.velocity.y).normalized();
      for (var i = 1; i <= 3; i++) {
        final trailOffset = trailDir * (radius * i * 0.8);
        canvas.drawCircle(
          Offset(trailOffset.x, trailOffset.y),
          radius * 0.6 / i,
          trailPaint,
        );
      }
    }
  }

  void _renderIceProjectile(Canvas canvas, Projectile projectile) {
    final lifeRatio = projectile.lifetime / projectile.maxLifetime;
    final radius = projectile.radius;

    // Draw glow
    final glowPaint = Paint()
      ..color = const Color(0xFF00DDFF).withValues(alpha: 0.3 * lifeRatio)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(Offset.zero, radius * 1.5, glowPaint);

    // Draw core (hexagon for ice crystal)
    final path = Path();
    for (var i = 0; i < 6; i++) {
      final angle = (i / 6) * 2 * pi;
      final x = cos(angle) * radius;
      final y = sin(angle) * radius;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    final corePaint = Paint()
      ..color = const Color(0xFF00DDFF)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, corePaint);

    // Draw bright center
    final centerPaint = Paint()
      ..color = const Color(0xFFAAFFFF)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset.zero, radius * 0.4, centerPaint);
  }

  void _renderLightningProjectile(Canvas canvas, Projectile projectile) {
    final lifeRatio = projectile.lifetime / projectile.maxLifetime;
    final radius = projectile.radius;

    // Draw electric glow
    final glowPaint = Paint()
      ..color = const Color(0xFFFFFF00).withValues(alpha: 0.4 * lifeRatio)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(Offset.zero, radius * 2, glowPaint);

    // Draw jagged lightning bolt shape
    final boltPaint = Paint()
      ..color = const Color(0xFFFFFF00)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final path = Path();
    path.moveTo(-radius, 0);
    path.lineTo(-radius * 0.5, -radius * 0.5);
    path.lineTo(0, 0);
    path.lineTo(radius * 0.5, radius * 0.5);
    path.lineTo(radius, 0);

    canvas.drawPath(path, boltPaint);

    // Draw core
    final corePaint = Paint()
      ..color = const Color(0xFFFFFFAA)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset.zero, radius * 0.5, corePaint);
  }

  /// Render spell cooldown indicators in HUD
  void renderSpellHUD(Canvas canvas, Size size, List<dynamic> equippedSpells) {
    // Render spell slots at top center
    final slotWidth = 40.0;
    final slotHeight = 40.0;
    final slotSpacing = 10.0;
    final totalWidth = (slotWidth * 3) + (slotSpacing * 2);
    final startX = size.width / 2 - totalWidth / 2;
    final startY = 20.0;

    for (var i = 0; i < 3; i++) {
      final x = startX + (slotWidth + slotSpacing) * i;
      final y = startY;

      _renderSpellSlot(canvas, x, y, slotWidth, slotHeight, i + 1, equippedSpells[i]);
    }
  }

  void _renderSpellSlot(Canvas canvas, double x, double y, double width, double height, int slotNumber, dynamic spell) {
    // Draw slot background
    final bgPaint = Paint()
      ..color = const Color(0xFF222222)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(x, y, width, height), bgPaint);

    // Draw border
    final borderPaint = Paint()
      ..color = const Color(0xFF666666)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRect(Rect.fromLTWH(x, y, width, height), borderPaint);

    // Draw slot number
    final textPainter = TextPainter(
      text: TextSpan(
        text: '$slotNumber',
        style: const TextStyle(
          color: Color(0xFF999999),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(x + 4, y + 4));

    if (spell != null) {
      // Draw spell icon (simple color coded circle)
      final iconColor = _getSpellColor(spell.type);
      final iconPaint = Paint()
        ..color = iconColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x + width / 2, y + height / 2 + 4), 8, iconPaint);

      // Draw cooldown overlay
      if (spell.currentCooldown > 0) {
        final cooldownRatio = spell.currentCooldown / spell.cooldown;
        final overlayPaint = Paint()
          ..color = const Color(0xFF000000).withValues(alpha: 0.7);
        canvas.drawRect(
          Rect.fromLTWH(x, y, width, height * cooldownRatio),
          overlayPaint,
        );
      }

      // Draw mana cost
      final costPainter = TextPainter(
        text: TextSpan(
          text: '${spell.manaCost.toInt()}',
          style: const TextStyle(
            color: Color(0xFFAA00FF),
            fontSize: 10,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      costPainter.layout();
      costPainter.paint(canvas, Offset(x + width - costPainter.width - 2, y + height - costPainter.height - 2));
    } else {
      // Empty slot
      final emptyPainter = TextPainter(
        text: const TextSpan(
          text: '-',
          style: TextStyle(
            color: Color(0xFF444444),
            fontSize: 20,
            fontFamily: 'monospace',
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      emptyPainter.layout();
      emptyPainter.paint(
        canvas,
        Offset(x + width / 2 - emptyPainter.width / 2, y + height / 2 - emptyPainter.height / 2),
      );
    }
  }

  Color _getSpellColor(dynamic spellType) {
    final typeStr = spellType.toString();
    if (typeStr.contains('fireball')) return const Color(0xFFFF6600);
    if (typeStr.contains('frostNova')) return const Color(0xFF00DDFF);
    if (typeStr.contains('soulDrain')) return const Color(0xFFAA00FF);
    if (typeStr.contains('lightningBolt')) return const Color(0xFFFFFF00);
    if (typeStr.contains('shieldBarrier')) return const Color(0xFF00FF00);
    return const Color(0xFFFFFFFF);
  }
}
