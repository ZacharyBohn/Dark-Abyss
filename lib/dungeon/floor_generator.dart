import 'dart:math';

import '../entities/drifter.dart';
import '../entities/enemy.dart';
import '../utils/math_utils.dart';
import 'platform.dart';
import 'room.dart';

/// Generates procedural dungeon floors
class FloorGenerator {
  final Random _random = Random();

  /// Generate a new dungeon floor
  DungeonFloor generate(int floorNumber) {
    final List<Room> rooms = [];
    final List<Platform> allPlatforms = [];
    final List<Enemy> allEnemies = [];

    // Floor dimensions grow with floor number
    final roomCount = 3 + (floorNumber ~/ 2).clamp(0, 4); // 3-7 rooms
    final roomWidth = 600.0 + floorNumber * 50;
    final roomHeight = 500.0 + floorNumber * 30;

    double currentX = 0;

    // Generate rooms from left to right
    for (int i = 0; i < roomCount; i++) {
      final RoomType type;
      if (i == 0) {
        type = RoomType.start;
      } else if (i == roomCount - 1) {
        type = RoomType.exit;
      } else if (_random.nextDouble() < 0.3) {
        type = RoomType.vertical;
      } else {
        type = RoomType.combat;
      }

      final room = _generateRoom(
        type: type,
        x: currentX,
        y: 0,
        width: roomWidth,
        height: roomHeight,
        floorNumber: floorNumber,
        isFirst: i == 0,
        isLast: i == roomCount - 1,
      );

      rooms.add(room);
      allPlatforms.addAll(room.platforms);
      allEnemies.addAll(room.enemies);

      currentX += roomWidth - 40; // Overlap rooms slightly for connectivity
    }

    final totalWidth = currentX + 40;
    final totalHeight = roomHeight;

    // Add floor (bottom boundary) across entire dungeon
    allPlatforms.add(Platform(
      x: 0,
      y: totalHeight - 20,
      width: totalWidth,
      height: 40,
      isOneWay: false, // Solid floor
    ));

    // Add ceiling
    allPlatforms.add(Platform(
      x: 0,
      y: -20,
      width: totalWidth,
      height: 20,
      isOneWay: false, // Solid ceiling
    ));

    // Add left wall
    allPlatforms.add(Platform(
      x: -20,
      y: 0,
      width: 20,
      height: totalHeight,
      isWall: true,
      isOneWay: false, // Solid wall
    ));

    // Add right wall
    allPlatforms.add(Platform(
      x: totalWidth,
      y: 0,
      width: 20,
      height: totalHeight,
      isWall: true,
      isOneWay: false, // Solid wall
    ));

    return DungeonFloor(
      floorNumber: floorNumber,
      rooms: rooms,
      allPlatforms: allPlatforms,
      allEnemies: allEnemies,
      totalWidth: totalWidth,
      totalHeight: totalHeight,
      playerSpawn: rooms.first.center + Vector2(0, -50),
      exitPosition: rooms.last.exitPosition ?? rooms.last.center,
    );
  }

  Room _generateRoom({
    required RoomType type,
    required double x,
    required double y,
    required double width,
    required double height,
    required int floorNumber,
    required bool isFirst,
    required bool isLast,
  }) {
    final List<Platform> platforms = [];
    final List<Enemy> enemies = [];
    Vector2? exitPosition;

    switch (type) {
      case RoomType.start:
        _generateStartRoom(platforms, x, y, width, height);
        break;
      case RoomType.combat:
        _generateCombatRoom(platforms, enemies, x, y, width, height, floorNumber);
        break;
      case RoomType.vertical:
        _generateVerticalRoom(platforms, enemies, x, y, width, height, floorNumber);
        break;
      case RoomType.treasure:
        _generateTreasureRoom(platforms, x, y, width, height);
        break;
      case RoomType.exit:
        exitPosition = _generateExitRoom(platforms, enemies, x, y, width, height, floorNumber);
        break;
    }

    return Room(
      type: type,
      x: x,
      y: y,
      width: width,
      height: height,
      platforms: platforms,
      enemies: enemies,
      exitPosition: exitPosition,
    );
  }

  void _generateStartRoom(
    List<Platform> platforms,
    double x, double y, double width, double height,
  ) {
    // Safe starting platform in the middle
    platforms.add(Platform(
      x: x + width * 0.2,
      y: y + height * 0.6,
      width: width * 0.3,
      height: 25,
    ));

    // Lower platform to the right
    platforms.add(Platform(
      x: x + width * 0.55,
      y: y + height * 0.75,
      width: width * 0.35,
      height: 25,
    ));

    // Upper platform
    platforms.add(Platform(
      x: x + width * 0.35,
      y: y + height * 0.4,
      width: width * 0.25,
      height: 20,
    ));
  }

  void _generateCombatRoom(
    List<Platform> platforms,
    List<Enemy> enemies,
    double x, double y, double width, double height,
    int floorNumber,
  ) {
    // Main floor platforms with gaps
    final platformCount = 2 + _random.nextInt(2);
    final platformWidth = (width - 100) / platformCount - 50;

    for (int i = 0; i < platformCount; i++) {
      final px = x + 50 + i * (platformWidth + 70);
      final py = y + height * 0.7 + _random.nextDouble() * 40 - 20;
      platforms.add(Platform(
        x: px,
        y: py,
        width: platformWidth,
        height: 25,
      ));
    }

    // Mid-level platforms
    final midCount = 1 + _random.nextInt(3);
    for (int i = 0; i < midCount; i++) {
      platforms.add(Platform(
        x: x + 80 + _random.nextDouble() * (width - 200),
        y: y + height * 0.35 + _random.nextDouble() * height * 0.2,
        width: 100 + _random.nextDouble() * 80,
        height: 20,
      ));
    }

    // Upper platforms
    if (_random.nextDouble() > 0.4) {
      platforms.add(Platform(
        x: x + width * 0.3 + _random.nextDouble() * width * 0.3,
        y: y + height * 0.15 + _random.nextDouble() * 40,
        width: 80 + _random.nextDouble() * 60,
        height: 18,
      ));
    }

    // Spawn enemies based on floor number
    final enemyCount = 2 + (floorNumber ~/ 2).clamp(0, 4);
    for (int i = 0; i < enemyCount; i++) {
      enemies.add(Drifter(
        position: Vector2(
          x + 100 + _random.nextDouble() * (width - 200),
          y + height * 0.3 + _random.nextDouble() * height * 0.3,
        ),
      ));
    }
  }

  void _generateVerticalRoom(
    List<Platform> platforms,
    List<Enemy> enemies,
    double x, double y, double width, double height,
    int floorNumber,
  ) {
    // Vertical shaft with ascending platforms
    final levels = 5 + _random.nextInt(3);
    final levelHeight = height / levels;

    for (int i = 0; i < levels; i++) {
      // Alternate left and right sides
      final isLeft = i % 2 == 0;
      final px = isLeft
          ? x + 40 + _random.nextDouble() * 80
          : x + width - 200 - _random.nextDouble() * 80;
      final py = y + height - (i + 1) * levelHeight + 20;

      platforms.add(Platform(
        x: px,
        y: py,
        width: 120 + _random.nextDouble() * 60,
        height: 20,
      ));

      // Add enemy on some platforms
      if (i > 0 && i < levels - 1 && _random.nextDouble() > 0.5) {
        enemies.add(Drifter(
          position: Vector2(px + 60, py - 40),
        ));
      }
    }

    // Add some walls for wall-jumping
    platforms.add(Platform(
      x: x + width * 0.45,
      y: y + height * 0.3,
      width: 30,
      height: height * 0.5,
      isWall: true,
    ));

    platforms.add(Platform(
      x: x + width * 0.55,
      y: y + height * 0.2,
      width: 30,
      height: height * 0.5,
      isWall: true,
    ));

    // Entry/exit platforms
    platforms.add(Platform(
      x: x + 30,
      y: y + height * 0.75,
      width: 150,
      height: 25,
    ));

    platforms.add(Platform(
      x: x + width - 180,
      y: y + height * 0.75,
      width: 150,
      height: 25,
    ));
  }

  void _generateTreasureRoom(
    List<Platform> platforms,
    double x, double y, double width, double height,
  ) {
    // Central treasure platform
    platforms.add(Platform(
      x: x + width * 0.35,
      y: y + height * 0.5,
      width: width * 0.3,
      height: 25,
    ));

    // Surrounding platforms
    platforms.add(Platform(
      x: x + 50,
      y: y + height * 0.7,
      width: 120,
      height: 20,
    ));

    platforms.add(Platform(
      x: x + width - 170,
      y: y + height * 0.7,
      width: 120,
      height: 20,
    ));
  }

  Vector2 _generateExitRoom(
    List<Platform> platforms,
    List<Enemy> enemies,
    double x, double y, double width, double height,
    int floorNumber,
  ) {
    // Entry platform
    platforms.add(Platform(
      x: x + 30,
      y: y + height * 0.7,
      width: 180,
      height: 25,
    ));

    // Step platforms leading to exit
    platforms.add(Platform(
      x: x + width * 0.25,
      y: y + height * 0.55,
      width: 140,
      height: 20,
    ));

    platforms.add(Platform(
      x: x + width * 0.45,
      y: y + height * 0.4,
      width: 140,
      height: 20,
    ));

    // Exit platform (elevated)
    final exitPlatformX = x + width * 0.6;
    final exitPlatformY = y + height * 0.25;
    platforms.add(Platform(
      x: exitPlatformX,
      y: exitPlatformY,
      width: 180,
      height: 25,
    ));

    // Guardian enemies (more on higher floors)
    final guardianCount = 1 + (floorNumber ~/ 3).clamp(0, 3);
    for (int i = 0; i < guardianCount; i++) {
      enemies.add(Drifter(
        position: Vector2(
          x + width * 0.3 + i * 100,
          y + height * 0.35,
        ),
      ));
    }

    // Exit position is above the exit platform
    return Vector2(exitPlatformX + 90, exitPlatformY - 30);
  }
}
