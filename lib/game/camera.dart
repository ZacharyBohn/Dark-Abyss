import '../data/constants.dart';
import '../utils/math_utils.dart';

class Camera {
  Vector2 position = Vector2.zero();
  Vector2 shake = Vector2.zero();
  Vector2 targetPosition = Vector2.zero();

  double viewportWidth = 0;
  double viewportHeight = 0;

  void setViewportSize(double width, double height) {
    viewportWidth = width;
    viewportHeight = height;
  }

  void follow(Vector2 target, double dt, {int facingDirection = 0}) {
    // Calculate target position with look-ahead
    targetPosition.x = target.x + facingDirection * cameraLookAhead;
    targetPosition.y = target.y;

    // Smooth follow using lerp
    position.x = lerpDouble(position.x, targetPosition.x, cameraSmoothing);
    position.y = lerpDouble(position.y, targetPosition.y, cameraSmoothing);

    // Update shake
    shake.x *= screenShakeDecay;
    shake.y *= screenShakeDecay;
    if (shake.length < 0.5) {
      shake = Vector2.zero();
    }
  }

  void addShake(double intensity) {
    shake.x = randomRange(-intensity, intensity);
    shake.y = randomRange(-intensity, intensity);
  }

  void snapTo(Vector2 target) {
    position.x = target.x;
    position.y = target.y;
    targetPosition.x = target.x;
    targetPosition.y = target.y;
  }

  Vector2 get offset {
    return Vector2(
      position.x - viewportWidth / 2 + shake.x,
      position.y - viewportHeight / 2 + shake.y,
    );
  }

  void clampToWorld(double worldWidth, double worldHeight) {
    final minX = viewportWidth / 2;
    final maxX = worldWidth - viewportWidth / 2;
    final minY = viewportHeight / 2;
    final maxY = worldHeight - viewportHeight / 2;

    if (worldWidth > viewportWidth) {
      position.x = clampDouble(position.x, minX, maxX);
    } else {
      position.x = worldWidth / 2;
    }

    if (worldHeight > viewportHeight) {
      position.y = clampDouble(position.y, minY, maxY);
    } else {
      position.y = worldHeight / 2;
    }
  }
}
