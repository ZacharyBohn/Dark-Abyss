import 'dart:math' as math;

class Vector2 {
  double x;
  double y;

  Vector2(this.x, this.y);

  Vector2.zero()
      : x = 0,
        y = 0;

  Vector2.fromAngle(double angle, [double length = 1.0])
      : x = math.cos(angle) * length,
        y = math.sin(angle) * length;

  Vector2 copy() => Vector2(x, y);

  Vector2 operator +(Vector2 other) => Vector2(x + other.x, y + other.y);

  Vector2 operator -(Vector2 other) => Vector2(x - other.x, y - other.y);

  Vector2 operator *(double scalar) => Vector2(x * scalar, y * scalar);

  Vector2 operator /(double scalar) => Vector2(x / scalar, y / scalar);

  Vector2 operator -() => Vector2(-x, -y);

  double get length => math.sqrt(x * x + y * y);

  double get lengthSquared => x * x + y * y;

  double get angle => math.atan2(y, x);

  Vector2 normalized() {
    final len = length;
    if (len == 0) return Vector2.zero();
    return Vector2(x / len, y / len);
  }

  void normalize() {
    final len = length;
    if (len == 0) return;
    x /= len;
    y /= len;
  }

  double distanceTo(Vector2 other) {
    final dx = x - other.x;
    final dy = y - other.y;
    return math.sqrt(dx * dx + dy * dy);
  }

  double distanceSquaredTo(Vector2 other) {
    final dx = x - other.x;
    final dy = y - other.y;
    return dx * dx + dy * dy;
  }

  double dot(Vector2 other) => x * other.x + y * other.y;

  Vector2 lerp(Vector2 target, double t) {
    return Vector2(
      x + (target.x - x) * t,
      y + (target.y - y) * t,
    );
  }

  void setFrom(Vector2 other) {
    x = other.x;
    y = other.y;
  }

  void setValues(double newX, double newY) {
    x = newX;
    y = newY;
  }

  @override
  String toString() => 'Vector2($x, $y)';
}

double lerpDouble(double a, double b, double t) {
  return a + (b - a) * t;
}

double clampDouble(double value, double min, double max) {
  if (value < min) return min;
  if (value > max) return max;
  return value;
}

double randomRange(double min, double max) {
  return min + math.Random().nextDouble() * (max - min);
}

int randomInt(int min, int max) {
  return min + math.Random().nextInt(max - min);
}

double degToRad(double degrees) => degrees * math.pi / 180.0;

double radToDeg(double radians) => radians * 180.0 / math.pi;
