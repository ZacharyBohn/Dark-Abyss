import 'package:flutter/material.dart';

import '../data/constants.dart';
import '../dungeon/platform.dart';
import '../game/game_state.dart';
import '../game/game_world.dart';
import '../ui/start_screen.dart';
import '../ui/upgrade_menu.dart';
import '../utils/math_utils.dart';
import 'effects_renderer.dart';
import 'enemy_renderer.dart';
import 'hub_renderer.dart';
import 'player_renderer.dart';
import 'portal_renderer.dart';
import 'spell_renderer.dart';

class GamePainter extends CustomPainter {
  final GameWorld world;
  final PlayerRenderer _playerRenderer = PlayerRenderer();
  final EnemyRenderer _enemyRenderer = EnemyRenderer();
  final EffectsRenderer _effectsRenderer = EffectsRenderer();
  final PortalRenderer _portalRenderer = PortalRenderer();
  final HubRenderer _hubRenderer = HubRenderer();
  final UpgradeMenuRenderer _menuRenderer = UpgradeMenuRenderer();
  final StartScreenRenderer _startScreenRenderer = StartScreenRenderer();
  final SpellRenderer _spellRenderer = SpellRenderer();

  GamePainter({required this.world});

  @override
  void paint(Canvas canvas, Size size) {
    // Start screen - render and return early
    if (world.gameState == GameState.startScreen) {
      _startScreenRenderer.render(canvas, size);
      return;
    }

    final cameraOffset = world.camera.offset;

    // Draw background gradient based on floor
    _drawBackground(canvas, size);

    // Draw platforms
    _drawPlatforms(canvas, cameraOffset);

    // Draw exit portal (behind entities)
    _portalRenderer.render(canvas, world.exitPortal, cameraOffset);

    // Draw hub return portal with distinct cyan color
    if (world.hubReturnPortal != null) {
      _portalRenderer.render(
        canvas,
        world.hubReturnPortal,
        cameraOffset,
        colorOverride: const Color(0xFF00FFFF),
      );
    }

    // Draw hub elements (vendors, decorations)
    if (world.gameState == GameState.hub) {
      _hubRenderer.render(
        canvas, size, world.vendors, cameraOffset, world.player.position,
      );
    }

    // Draw pickups (behind entities)
    _effectsRenderer.renderPickups(canvas, world.pickups, cameraOffset);

    // Draw enemies
    _enemyRenderer.render(canvas, world.enemies, cameraOffset);

    // Draw player
    _playerRenderer.render(canvas, world.player, cameraOffset);

    // Draw particles (on top of entities)
    _effectsRenderer.renderParticles(canvas, world.combat.particles, cameraOffset);

    // Draw spell projectiles
    _spellRenderer.renderProjectiles(canvas, world.spellManager.projectiles, cameraOffset);

    // Draw damage numbers (on top of everything in game world)
    _effectsRenderer.renderDamageNumbers(canvas, world.combat.damageNumbers, cameraOffset);

    // Draw hub portal prompt
    if (world.gameState == GameState.hub && world.exitPortal != null) {
      if (world.exitPortal!.isPlayerInRange(world.player.position)) {
        final floorLabel = world.dungeonCheckpointFloor > 1
            ? 'Press E to Enter Dungeon (Floor ${world.dungeonCheckpointFloor})'
            : 'Press E to Enter Dungeon';
        final promptPainter = TextPainter(
          text: TextSpan(
            text: floorLabel,
            style: const TextStyle(
              color: Color(0xFF00FF88),
              fontSize: 14,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        promptPainter.layout();
        final portalScreenX = world.exitPortal!.position.x - cameraOffset.x;
        final portalScreenY = world.exitPortal!.position.y - cameraOffset.y;
        promptPainter.paint(
          canvas,
          Offset(portalScreenX - promptPainter.width / 2, portalScreenY - 60),
        );
      }
    }

    // Draw hub return portal prompt
    if (world.gameState == GameState.dungeon && world.hubReturnPortal != null &&
        world.hubReturnPortal!.isUnlocked) {
      final portal = world.hubReturnPortal!;
      final portalScreenX = portal.position.x - cameraOffset.x;
      final portalScreenY = portal.position.y - cameraOffset.y;

      // Label above portal
      final labelPainter = TextPainter(
        text: const TextSpan(
          text: 'RETURN TO HUB',
          style: TextStyle(
            color: Color(0xFF00FFFF),
            fontSize: 12,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      labelPainter.layout();
      labelPainter.paint(
        canvas,
        Offset(portalScreenX - labelPainter.width / 2, portalScreenY - 60),
      );
    }

    // Draw HUD (on top of everything)
    _drawHUD(canvas, size);

    // Draw death overlay
    if (world.gameState == GameState.dungeon && world.player.isDead) {
      _drawDeathOverlay(canvas, size);
    }

    // Draw transition overlay
    if (world.isTransitioning) {
      _drawTransition(canvas, size);
    }

    // Draw upgrade menu overlay
    if (world.gameState == GameState.menu && world.activeMenu != null) {
      _menuRenderer.render(
        canvas,
        size,
        world.activeMenu!,
        world.upgradeManager,
        world.currencyManager,
      );
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

    // Show contextual text at peak
    if (progress > 0.3 && progress < 0.7) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: world.transitionText,
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

  void _drawDeathOverlay(Canvas canvas, Size size) {
    // Red tint
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.red.withValues(alpha: 0.2),
    );

    // "YOU DIED" text
    final deathText = TextPainter(
      text: const TextSpan(
        text: 'YOU DIED',
        style: TextStyle(
          color: Color(0xFFFF4444),
          fontSize: 48,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    deathText.layout();
    deathText.paint(
      canvas,
      Offset(size.width / 2 - deathText.width / 2, size.height / 2 - 50),
    );

    // Gold loss info
    final lostGold = (world.currencyManager.sessionGold * 0.5).round();
    if (lostGold > 0) {
      final lossText = TextPainter(
        text: TextSpan(
          text: '-${lostGold}g',
          style: const TextStyle(
            color: Color(0xFFFFDD00),
            fontSize: 20,
            fontFamily: 'monospace',
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      lossText.layout();
      lossText.paint(
        canvas,
        Offset(size.width / 2 - lossText.width / 2, size.height / 2 + 20),
      );
    }
  }

  void _drawBackground(Canvas canvas, Size size) {
    final bgColor = world.gameState == GameState.hub
        ? const Color(0xFF0A0818)
        : getFloorBackgroundColor(world.currentFloor);
    final paint = Paint()..color = bgColor;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Add subtle gradient overlay
    final topColor = world.gameState == GameState.hub
        ? const Color(0xFF120828).withValues(alpha: 0.5)
        : bgColor.withValues(alpha: 0.5);
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        topColor,
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
    final floorColor = world.gameState == GameState.hub
        ? const Color(0xFF00FFFF)
        : getFloorPrimaryColor(world.currentFloor);

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

    // Location info (top left)
    if (world.gameState == GameState.hub) {
      final hubText = TextPainter(
        text: const TextSpan(
          text: 'HUB',
          style: TextStyle(
            color: Color(0xFF00FFFF),
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      hubText.layout();
      hubText.paint(canvas, const Offset(10, 10));
    } else {
      // Show floor number with checkpoint indicator
      final floorsUntilCheckpoint =
          checkpointFloorInterval - (world.currentFloor % checkpointFloorInterval);
      final checkpointHint = floorsUntilCheckpoint == checkpointFloorInterval
          ? ' (checkpoint!)' // We're on a checkpoint floor
          : '';
      final floorText = TextPainter(
        text: TextSpan(
          text: 'Floor: ${world.currentFloor}$checkpointHint',
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
    }

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

    // Player Mana bar
    _drawBar(
      canvas: canvas,
      x: 10,
      y: 65,
      width: 150,
      height: 8,
      fillRatio: player.currentMana / player.maxMana,
      fillColor: const Color(0xFFAA00FF),
      label: 'MP',
    );

    // Enemy count (dungeon only)
    if (world.gameState == GameState.dungeon) {
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
      enemyText.paint(canvas, const Offset(10, 83));
    }

    // Currency display (top right, below FPS)
    _drawCurrencyHUD(canvas, size);

    // Spell HUD (dungeon only)
    if (world.gameState == GameState.dungeon) {
      _spellRenderer.renderSpellHUD(canvas, size, world.spellManager.equippedSpells);
    }

    // Controls hint
    final controlsHint = world.gameState == GameState.hub
        ? 'WASD: Move | Space: Jump | E: Interact'
        : 'WASD: Move | Space: Jump | K/Shift: Dash | J/Z: Attack | 1-3: Spells';
    final controlsText = TextPainter(
      text: TextSpan(
        text: controlsHint,
        style: const TextStyle(
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

  void _drawCurrencyHUD(Canvas canvas, Size size) {
    final currency = world.currencyManager;

    // Gold display with coin icon
    final goldY = 30.0;
    final goldX = size.width - 120;

    // Draw gold coin icon (yellow circle)
    final coinPaint = Paint()..color = const Color(0xFFFFDD00);
    canvas.drawCircle(Offset(goldX, goldY), 8, coinPaint);
    final coinHighlight = Paint()
      ..color = const Color(0xFFFFFFAA)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(Offset(goldX - 2, goldY - 2), 4, coinHighlight);

    // Gold amount text
    final goldText = TextPainter(
      text: TextSpan(
        text: '${currency.gold}',
        style: const TextStyle(
          color: Color(0xFFFFDD00),
          fontSize: 16,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    goldText.layout();
    goldText.paint(canvas, Offset(goldX + 14, goldY - goldText.height / 2));

    // Essence display with star icon
    final essenceY = 52.0;
    final essenceX = size.width - 120;

    // Draw essence star icon (purple star)
    _drawStar(canvas, Offset(essenceX, essenceY), 8, const Color(0xFFAA00FF));

    // Essence amount text
    final essenceText = TextPainter(
      text: TextSpan(
        text: '${currency.essence}',
        style: const TextStyle(
          color: Color(0xFFAA00FF),
          fontSize: 16,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    essenceText.layout();
    essenceText.paint(canvas, Offset(essenceX + 14, essenceY - essenceText.height / 2));
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Color color) {
    final paint = Paint()..color = color;
    final path = Path();

    const pi = 3.14159265;
    final outerRadius = radius;
    final innerRadius = radius * 0.4;

    // Draw 5-point star (10 points alternating outer/inner)
    for (int i = 0; i < 10; i++) {
      final r = i.isEven ? outerRadius : innerRadius;
      final angle = (i * 36 - 90) * pi / 180;
      // Use simple trig
      final starX = center.dx + r * _cosApprox(angle);
      final starY = center.dy + r * _sinApprox(angle);
      if (i == 0) {
        path.moveTo(starX, starY);
      } else {
        path.lineTo(starX, starY);
      }
    }
    path.close();

    // Add glow
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawPath(path, glowPaint);

    canvas.drawPath(path, paint);
  }

  // Simple cosine approximation
  double _cosApprox(double x) {
    const pi = 3.14159265;
    const twoPi = 6.28318530;
    // Normalize to [-pi, pi]
    while (x > pi) {
      x -= twoPi;
    }
    while (x < -pi) {
      x += twoPi;
    }
    // Taylor series approximation
    final x2 = x * x;
    return 1 - x2 / 2 + x2 * x2 / 24 - x2 * x2 * x2 / 720;
  }

  // Simple sine approximation
  double _sinApprox(double x) {
    const pi = 3.14159265;
    const twoPi = 6.28318530;
    // Normalize to [-pi, pi]
    while (x > pi) {
      x -= twoPi;
    }
    while (x < -pi) {
      x += twoPi;
    }
    // Taylor series approximation
    final x2 = x * x;
    return x - x * x2 / 6 + x * x2 * x2 / 120 - x * x2 * x2 * x2 / 5040;
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
