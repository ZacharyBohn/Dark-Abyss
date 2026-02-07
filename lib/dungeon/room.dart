import '../entities/enemy.dart';
import '../utils/math_utils.dart';
import 'platform.dart';

/// Types of rooms that can be generated
enum RoomType {
  start,      // Starting room - safe, no enemies
  combat,     // Combat room with enemies
  vertical,   // Tall room with vertical platforming
  treasure,   // Contains bonus pickups
  exit,       // Contains the exit portal
}

/// A room in the dungeon floor
class Room {
  final RoomType type;
  final double x;
  final double y;
  final double width;
  final double height;
  final List<Platform> platforms;
  final List<Enemy> enemies;
  final Vector2? exitPosition;

  Room({
    required this.type,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.platforms,
    required this.enemies,
    this.exitPosition,
  });

  /// Get the center position of this room
  Vector2 get center => Vector2(x + width / 2, y + height / 2);

  /// Check if a point is inside this room
  bool contains(Vector2 point) {
    return point.x >= x &&
           point.x <= x + width &&
           point.y >= y &&
           point.y <= y + height;
  }
}

/// A complete dungeon floor made up of connected rooms
class DungeonFloor {
  final int floorNumber;
  final List<Room> rooms;
  final List<Platform> allPlatforms;
  final List<Enemy> allEnemies;
  final double totalWidth;
  final double totalHeight;
  final Vector2 playerSpawn;
  final Vector2 exitPosition;

  DungeonFloor({
    required this.floorNumber,
    required this.rooms,
    required this.allPlatforms,
    required this.allEnemies,
    required this.totalWidth,
    required this.totalHeight,
    required this.playerSpawn,
    required this.exitPosition,
  });
}
