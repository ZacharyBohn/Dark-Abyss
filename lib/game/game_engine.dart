import 'package:flutter/scheduler.dart';

import 'game_world.dart';

class GameEngine {
  final GameWorld world = GameWorld();
  final TickerProvider tickerProvider;

  Ticker? _ticker;
  Duration _lastTime = Duration.zero;
  bool _isRunning = false;

  // Callback to notify UI to repaint
  void Function()? onUpdate;

  GameEngine({required this.tickerProvider});

  void start() {
    if (_isRunning) return;

    _isRunning = true;
    _lastTime = Duration.zero;
    _ticker = tickerProvider.createTicker(_onTick);
    _ticker!.start();
  }

  void stop() {
    _isRunning = false;
    _ticker?.stop();
    _ticker?.dispose();
    _ticker = null;
  }

  void pause() {
    _ticker?.muted = true;
  }

  void resume() {
    _ticker?.muted = false;
  }

  void _onTick(Duration elapsed) {
    if (!_isRunning) return;

    // Calculate delta time in seconds
    final dt = _lastTime == Duration.zero
        ? 0.016 // Default to ~60fps on first frame
        : (elapsed - _lastTime).inMicroseconds / 1000000.0;
    _lastTime = elapsed;

    // Cap delta time to prevent huge jumps
    final cappedDt = dt.clamp(0.0, 0.1);

    // Update game world
    world.update(cappedDt);

    // Notify UI to repaint
    onUpdate?.call();
  }

  void dispose() {
    stop();
  }
}
