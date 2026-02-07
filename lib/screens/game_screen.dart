import 'package:flutter/material.dart';

import '../audio/audio_manager.dart';
import '../game/game_engine.dart';
import '../game/input_handler.dart';
import '../rendering/game_painter.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  late GameEngine _engine;
  final FocusNode _focusNode = FocusNode();
  final InputHandler _inputHandler = InputHandler();
  final AudioManager _audioManager = AudioManager();

  @override
  void initState() {
    super.initState();
    _engine = GameEngine(tickerProvider: this);
    _engine.onUpdate = _onGameUpdate;
    _engine.start();
    _audioManager.playMusic();
  }

  void _onGameUpdate() {
    if (!mounted) return;

    // Handle input
    _engine.world.handleInput(_inputHandler.state, 0.016);

    // Clear pressed flags after processing
    _inputHandler.state.clearPressedFlags();

    setState(() {});
  }

  @override
  void dispose() {
    _audioManager.stopMusic();
    _engine.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    _inputHandler.handleKeyEvent(event);
    // Return handled to prevent key events from propagating to macOS
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Focus(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _handleKeyEvent,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) {
            _focusNode.requestFocus();
          },
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Update viewport size
              _engine.world.setViewportSize(
                constraints.maxWidth,
                constraints.maxHeight,
              );

              return Stack(
                children: [
                  CustomPaint(
                    painter: GamePainter(world: _engine.world),
                    size: Size(constraints.maxWidth, constraints.maxHeight),
                  ),
                  // Mute button
                  Positioned(
                    top: 8,
                    right: 80,
                    child: IconButton(
                      icon: Icon(
                        _audioManager.isMuted
                            ? Icons.volume_off
                            : Icons.volume_up,
                        color: Colors.white70,
                        size: 20,
                      ),
                      onPressed: () {
                        _audioManager.toggleMute();
                        setState(() {});
                      },
                      tooltip: _audioManager.isMuted ? 'Unmute' : 'Mute',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
