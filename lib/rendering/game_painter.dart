import 'package:flutter/material.dart';

import '../data/constants.dart';
import '../dungeon/platform.dart';
import '../game/game_world.dart';
import '../utils/math_utils.dart';
import 'effects_renderer.dart';
import 'enemy_renderer.dart';
import 'player_renderer.dart';
import 'portal_renderer.dart';

class GamePainter extends CustomPainter {
  final GameWorld world;
  final PlayerRenderer _playerRenderer = PlayerRenderer();
  final EnemyRenderer _enemyRenderer = EnemyRenderer();
  final EffectsRenderer _effectsRenderer = EffectsRenderer();
  final PortalRenderer _portalRenderer = PortalRenderer();

  GamePainter({required this.world});

  @override
  void paint(Canvas canvas, Size size) {
    final cameraOffset = world.camera.offset;

    // Draw background gradient based on floor
    _drawBackground(canvas, size);

    // Draw platforms
    _drawPlatforms(canvas, cameraOffset);

    // Draw exit portal (behind entities)
    _portalRenderer.render(canvas, world.exitPortal, cameraOffset);

    // Draw pickups (behind entities)
    _effectsRenderer.renderPickups(canvas, world.pickups, cameraOffset);

    // Draw enemies
    _enemyRenderer.render(canvas, world.enemies, cameraOffset);

    // Draw player
    _playerRenderer.render(canvas, world.player, cameraOffset);

    // Draw particles (on top of entities)
    _effectsRenderer.renderParticles(canvas, world.combat.particles, cameraOffset);

    // Draw damage numbers (on top of everything in game world)
    _effectsRenderer.renderDamageNumbers(canvas, world.combat.damageNumbers, cameraOffset);

    // Draw HUD (on top of everything)
    _drawHUD(canvas, size);

    // Draw transition overlay
    if (world.isTransitioning) {
      _drawTransition(canvas, size);
    }
  }

  void _drawTransition(Canvas canvas, Size size) {
    // Fade to black then fade in
    final progress = 1.0 - world.transitionTimer;
    final alpha = progress < 0.5
        ? progress * 2  // Fade out
        : (1.0 - progress) * 2;  // Fade in

    final paint = Paint()
      ..color = Colors.black.withValues(alpha: alpha.clamp(0, 1));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Show floor number text at peak
    if (progress > 0.3 && progress < 0.7) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: 'Floor ${world.currentFloor + 1}',
          style: TextStyle(
            color: Colors.white.withValues(alpha: (1.0 - (progress - 0.5).abs() * 5).clamp(0, 1)),
            fontSize: 48,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(size.width / 2 - textPainter.width / 2, size.height / 2 - textPainter.height / 2),
      );
    }
  }

  void _drawBackground(Canvas canvas, Size size) {
    final bgColor = getFloorBackgroundColor(world.currentFloor);
    final paint = Paint()..color = bgColor;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Add subtle gradient overlay
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        bgColor.withValues(alpha: 0.5),
        bgColor,
        bgColor.withValues(alpha: 0.8),
      ],
    );

    final gradientPaint = Paint()
      ..shader =
          gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), gradientPaint);
  }

  void _drawPlatforms(Canvas canvas, Vector2 cameraOffset) {
    final floorColor = getFloorPrimaryColor(world.currentFloor);

    for (final platform in world.platforms) {
      _drawPlatform(canvas, platform, cameraOffset, floorColor);
    }
  }

  void _drawPlatform(
    Canvas canvas,
    Platform platform,
    Vector2 cameraOffset,
    Color floorColor,
  ) {
    final rect = Rect.fromLTWH(
      platform.x - cameraOffset.x,
      platform.y - cameraOffset.y,
      platform.width,
      platform.height,
    );

    // Glow effect
    final glowPaint = Paint()
      ..color = floorColor.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawRect(rect.inflate(4), glowPaint);

    // Main platform fill
    final fillPaint = Paint()
      ..color = platformColor
      ..style = PaintingStyle.fill;
    canvas.drawRect(rect, fillPaint);

    // Top edge highlight
    final topEdgePaint = Paint()
      ..color = floorColor.withValues(alpha: 0.6)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      rect.topLeft,
      rect.topRight,
      topEdgePaint,
    );

    // Subtle inner glow at top
    final innerGlowRect = Rect.fromLTWH(
      rect.left,
      rect.top,
      rect.width,
      platform.height.clamp(0, 10).toDouble(),
    );
    final innerGlowGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        floorColor.withValues(alpha: 0.2),
        Colors.transparent,
      ],
    );
    final innerGlowPaint = Paint()
      ..shader = innerGlowGradient.createShader(innerGlowRect);
    canvas.drawRect(innerGlowRect, innerGlowPaint);
  }

  void _drawHUD(Canvas canvas, Size size) {
    // FPS counter
    final fpsText = TextPainter(
      text: TextSpan(
        text: 'FPS: ${world.currentFps.toStringAsFixed(1)}',
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 14,
          fontFamily: 'monospace',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    fpsText.layout();
    fpsText.paint(canvas, Offset(size.width - fpsText.width - 10, 10));

    // Floor info
    final floorText = TextPainter(
      text: TextSpan(
        text: 'Floor: ${world.currentFloor}',
        style: TextStyle(
          color: getFloorPrimaryColor(world.currentFloor),
          fontSize: 18,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    floorText.layout();
    floorText.paint(canvas, const Offset(10, 10));

    // Player HP bar
    final player = world.player;
    _drawBar(
      canvas: canvas,
      x: 10,
      y: 35,
      width: 150,
      height: 12,
      fillRatio: player.currentHP / player.maxHP,
      fillColor: const Color(0xFF00FF88),
      label: 'HP',
    );

    // Player Energy bar
    _drawBar(
      canvas: canvas,
      x: 10,
      y: 52,
      width: 150,
      height: 8,
      fillRatio: player.currentEnergy / player.maxEnergy,
      fillColor: const Color(0xFF00AAFF),
      label: 'EN',
    );

    // Enemy count
    final enemyText = TextPainter(
      text: TextSpan(
        text: 'Enemies: ${world.enemies.length}',
        style: const TextStyle(
          color: Colors.white54,
          fontSize: 12,
          fontFamily: 'monospace',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    enemyText.layout();
    enemyText.paint(canvas, const Offset(10, 70));

    // Controls hint
    final controlsText = TextPainter(
      text: const TextSpan(
        text: 'WASD: Move | Space: Jump | K/Shift: Dash | J/Z: Attack',
        style: TextStyle(
          color: Colors.white38,
          fontSize: 12,
          fontFamily: 'monospace',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    controlsText.layout();
    controlsText.paint(
      canvas,
      Offset(size.width / 2 - controlsText.width / 2, size.height - 30),
    );
  }

  void _drawBar({
    required Canvas canvas,
    required double x,
    required double y,
    required double width,
    required double height,
    required double fillRatio,
    required Color fillColor,
    required String label,
  }) {
    // Background
    canvas.drawRect(
      Rect.fromLTWH(x, y, width, height),
      Paint()..color = Colors.black54,
    );

    // Fill
    canvas.drawRect(
      Rect.fromLTWH(x, y, width * fillRatio.clamp(0, 1), height),
      Paint()..color = fillColor,
    );

    // Border
    canvas.drawRect(
      Rect.fromLTWH(x, y, width, height),
      Paint()
        ..color = Colors.white24
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // Label
    final labelPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 10,
          fontFamily: 'monospace',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    labelPainter.layout();
    labelPainter.paint(canvas, Offset(x + 4, y + (height - labelPainter.height) / 2));
  }

  @override
  bool shouldRepaint(covariant GamePainter oldDelegate) {
    return true;
  }
}
