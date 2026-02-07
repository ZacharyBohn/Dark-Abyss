import 'package:flutter/services.dart';

import '../utils/math_utils.dart';

class InputState {
  bool left = false;
  bool right = false;
  bool up = false;
  bool down = false;
  bool jump = false;
  bool dash = false;
  bool attack = false;
  bool special = false;

  // For detecting just-pressed (edge detection)
  bool jumpPressed = false;
  bool dashPressed = false;
  bool attackPressed = false;

  Vector2 get moveDirection {
    double x = 0;
    double y = 0;
    if (left) x -= 1;
    if (right) x += 1;
    if (up) y -= 1;
    if (down) y += 1;
    final dir = Vector2(x, y);
    if (dir.length > 0) dir.normalize();
    return dir;
  }

  int get horizontalInput {
    if (left && !right) return -1;
    if (right && !left) return 1;
    return 0;
  }

  void clearPressedFlags() {
    jumpPressed = false;
    dashPressed = false;
    attackPressed = false;
  }
}

class InputHandler {
  final InputState state = InputState();

  void handleKeyEvent(KeyEvent event) {
    final isDown = event is KeyDownEvent;
    final isUp = event is KeyUpEvent;

    // Determine which key was affected
    final key = event.logicalKey;

    // Movement keys
    if (key == LogicalKeyboardKey.keyA ||
        key == LogicalKeyboardKey.arrowLeft) {
      state.left = isDown || (!isUp && state.left);
      if (isUp) state.left = false;
    }
    if (key == LogicalKeyboardKey.keyD ||
        key == LogicalKeyboardKey.arrowRight) {
      state.right = isDown || (!isUp && state.right);
      if (isUp) state.right = false;
    }
    if (key == LogicalKeyboardKey.keyW || key == LogicalKeyboardKey.arrowUp) {
      state.up = isDown || (!isUp && state.up);
      if (isUp) state.up = false;
    }
    if (key == LogicalKeyboardKey.keyS ||
        key == LogicalKeyboardKey.arrowDown) {
      state.down = isDown || (!isUp && state.down);
      if (isUp) state.down = false;
    }

    // Jump (Space)
    if (key == LogicalKeyboardKey.space) {
      if (isDown && !state.jump) {
        state.jumpPressed = true;
      }
      state.jump = isDown || (!isUp && state.jump);
      if (isUp) state.jump = false;
    }

    // Dash (K or Shift) - K is on right side for WASD users
    if (key == LogicalKeyboardKey.keyK ||
        key == LogicalKeyboardKey.shiftLeft ||
        key == LogicalKeyboardKey.shiftRight) {
      if (isDown && !state.dash) {
        state.dashPressed = true;
      }
      state.dash = isDown || (!isUp && state.dash);
      if (isUp) state.dash = false;
    }

    // Attack (J or Z)
    if (key == LogicalKeyboardKey.keyJ || key == LogicalKeyboardKey.keyZ) {
      if (isDown && !state.attack) {
        state.attackPressed = true;
      }
      state.attack = isDown || (!isUp && state.attack);
      if (isUp) state.attack = false;
    }

    // Special (L or X) - hold for charge
    if (key == LogicalKeyboardKey.keyL || key == LogicalKeyboardKey.keyX) {
      state.special = isDown || (!isUp && state.special);
      if (isUp) state.special = false;
    }
  }
}
