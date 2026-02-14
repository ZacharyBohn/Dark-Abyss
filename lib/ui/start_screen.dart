import 'package:flutter/material.dart';

class StartScreenRenderer {
  void render(Canvas canvas, Size size) {
    // Dark background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF0A0A1A),
    );

    // Title
    final titlePainter = TextPainter(
      text: const TextSpan(
        text: 'ABYSS RUNNER',
        style: TextStyle(
          color: Color(0xFF00FF88),
          fontSize: 48,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
          letterSpacing: 4,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    titlePainter.layout();
    titlePainter.paint(
      canvas,
      Offset(
        (size.width - titlePainter.width) / 2,
        size.height / 3,
      ),
    );

    // Subtitle / tagline
    final subtitlePainter = TextPainter(
      text: const TextSpan(
        text: 'Descend Into The Unknown',
        style: TextStyle(
          color: Color(0xFFAA00FF),
          fontSize: 18,
          fontFamily: 'monospace',
          letterSpacing: 2,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    subtitlePainter.layout();
    subtitlePainter.paint(
      canvas,
      Offset(
        (size.width - subtitlePainter.width) / 2,
        size.height / 3 + 70,
      ),
    );

    // Pulsing "Press Any Key" text
    final time = DateTime.now().millisecondsSinceEpoch / 1000.0;
    final pulseAlpha = 0.5 + 0.5 * (time % 2.0) / 2.0;

    final startPainter = TextPainter(
      text: TextSpan(
        text: 'PRESS ANY KEY TO START',
        style: TextStyle(
          color: Colors.white.withValues(alpha: pulseAlpha),
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
          letterSpacing: 2,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    startPainter.layout();
    startPainter.paint(
      canvas,
      Offset(
        (size.width - startPainter.width) / 2,
        size.height * 0.65,
      ),
    );

    // Controls hint
    final controlsPainter = TextPainter(
      text: const TextSpan(
        text: 'WASD/Arrows: Move | Space: Jump | Shift: Dash | J: Attack | E: Interact',
        style: TextStyle(
          color: Colors.white38,
          fontSize: 12,
          fontFamily: 'monospace',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    controlsPainter.layout();
    controlsPainter.paint(
      canvas,
      Offset(
        (size.width - controlsPainter.width) / 2,
        size.height - 60,
      ),
    );
  }
}
