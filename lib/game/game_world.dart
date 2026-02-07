import 'dart:ui';

import '../combat/combat_system.dart';
import '../dungeon/exit_portal.dart';
import '../dungeon/floor_generator.dart';
import '../dungeon/platform.dart';
import '../dungeon/room.dart';
import '../entities/enemy.dart';
import '../entities/pickup.dart';
import '../entities/player.dart';
import '../utils/math_utils.dart';
import 'camera.dart';
import 'input_handler.dart';

class GameWorld {
  int currentFloor = 1;
  double gameTime = 0;

  // Player
  late Player player;

  // Camera
  final Camera camera = Camera();

  // Platforms
  List<Platform> platforms = [];

  // Enemies
  List<Enemy> enemies = [];

  // Pickups
  List<Pickup> pickups = [];

  // Combat
  final CombatSystem combat = CombatSystem();

  // Dungeon
  final FloorGenerator _floorGenerator = FloorGenerator();
  DungeonFloor? _currentDungeon;
  ExitPortal? exitPortal;

  // World bounds
  double worldWidth = 1600;
  double worldHeight = 900;

  // FPS tracking
  int frameCount = 0;
  double fpsAccumulator = 0;
  double currentFps = 0;

  // Floor transition
  bool isTransitioning = false;
  double transitionTimer = 0;

  GameWorld() {
    _generateFloor(1);
  }

  void _generateFloor(int floor) {
    currentFloor = floor;

    // Generate dungeon
    _currentDungeon = _floorGenerator.generate(floor);

    // Set up world from dungeon
    platforms = List.from(_currentDungeon!.allPlatforms);
    enemies = List.from(_currentDungeon!.allEnemies);
    pickups = [];

    worldWidth = _currentDungeon!.totalWidth;
    worldHeight = _currentDungeon!.totalHeight;

    // Create player at spawn point
    player = Player(position: _currentDungeon!.playerSpawn.copy());

    // Create exit portal
    exitPortal = ExitPortal(position: _currentDungeon!.exitPosition.copy());
    exitPortal!.isUnlocked = false;
  }

  void _goToNextFloor() {
    isTransitioning = true;
    transitionTimer = 1.0; // 1 second transition
  }

  void _completeTransition() {
    isTransitioning = false;
    _generateFloor(currentFloor + 1);
    camera.snapTo(player.position);
  }

  void handleInput(InputState input, double dt) {
    player.handleInput(input, dt);
  }

  void update(double dt) {
    gameTime += dt;

    // FPS calculation
    frameCount++;
    fpsAccumulator += dt;
    if (fpsAccumulator >= 1.0) {
      currentFps = frameCount / fpsAccumulator;
      frameCount = 0;
      fpsAccumulator = 0;
    }

    // Handle floor transition
    if (isTransitioning) {
      transitionTimer -= dt;
      if (transitionTimer <= 0) {
        _completeTransition();
      }
      return; // Don't update anything else during transition
    }

    // Update player
    player.update(dt);

    // Update enemies
    for (final enemy in enemies) {
      enemy.targetPosition = player.position;
      enemy.platforms = platforms; // Give enemies platform awareness for pathfinding
      enemy.update(dt);
    }

    // Remove dead enemies after death animation
    enemies.removeWhere((e) => e.isDead && e.deathTimer <= 0);

    // Update pickups
    for (final pickup in pickups) {
      pickup.update(dt, player.position);
    }
    pickups.removeWhere((p) => p.shouldRemove);

    // Add pending pickups from combat
    pickups.addAll(combat.pendingPickups);
    combat.pendingPickups.clear();

    // Process combat
    combat.processPlayerAttacks(player, enemies);
    combat.processEnemyAttacks(player, enemies);
    combat.processPickups(player, pickups);
    combat.update(dt);

    // Update exit portal
    if (exitPortal != null) {
      exitPortal!.update(dt);

      // Unlock portal when all enemies are defeated
      if (!exitPortal!.isUnlocked && enemies.isEmpty) {
        exitPortal!.isUnlocked = true;
      }

      // Check if player enters unlocked portal
      if (exitPortal!.isUnlocked && exitPortal!.isPlayerInRange(player.position)) {
        _goToNextFloor();
      }
    }

    // Handle collisions
    _handleCollisions();
    _handleEnemyCollisions();

    // Update camera
    camera.follow(
      player.position,
      dt,
      facingDirection: player.facingRight ? 1 : -1,
    );
    camera.clampToWorld(worldWidth, worldHeight);
  }

  void _handleCollisions() {
    // Reset collision states
    bool groundedThisFrame = false;
    bool touchingWallLeft = false;
    bool touchingWallRight = false;

    final feetRect = player.feetRect;
    final leftRect = player.leftRect;
    final rightRect = player.rightRect;
    final playerRect = player.hitbox;

    for (final platform in platforms) {
      final platRect = platform.rect;

      // Ground collision (only when moving down or stationary)
      if (player.velocity.y >= 0 && feetRect.overlaps(platRect)) {
        // Check if player was above platform
        if (player.position.y + player.height / 2 - player.velocity.y * 0.017 <=
            platform.top + 10) {
          player.position.y = platform.top - player.height / 2;
          groundedThisFrame = true;
        }
      }

      // Wall collisions
      if (platform.isWall || platform.height > 50) {
        if (leftRect.overlaps(platRect)) {
          touchingWallLeft = true;
          // Push player out of wall
          if (playerRect.overlaps(platRect)) {
            player.position.x = platform.right + player.width / 2;
          }
        }

        if (rightRect.overlaps(platRect)) {
          touchingWallRight = true;
          // Push player out of wall
          if (playerRect.overlaps(platRect)) {
            player.position.x = platform.left - player.width / 2;
          }
        }
      }

      // Head collision (stop upward movement)
      if (player.velocity.y < 0) {
        final headRect = Rect.fromLTWH(
          player.position.x - player.width / 2 + 4,
          player.position.y - player.height / 2 - 2,
          player.width - 8,
          4,
        );
        if (headRect.overlaps(platRect)) {
          player.velocity.y = 0;
          player.position.y = platform.bottom + player.height / 2 + 2;
        }
      }
    }

    // Update player ground state
    if (groundedThisFrame && !player.isGrounded) {
      player.onLand();
    } else if (!groundedThisFrame && player.isGrounded) {
      player.onLeaveGround();
    }
    player.isGrounded = groundedThisFrame;

    // Update wall state
    if (touchingWallLeft) {
      player.onTouchWall(-1);
    } else if (touchingWallRight) {
      player.onTouchWall(1);
    } else if (player.wallDirection != 0) {
      player.onLeaveWall();
    }

    // World bounds
    if (player.position.x < player.width / 2) {
      player.position.x = player.width / 2;
      player.velocity.x = 0;
    }
    if (player.position.x > worldWidth - player.width / 2) {
      player.position.x = worldWidth - player.width / 2;
      player.velocity.x = 0;
    }

    // Fall off bottom - should not happen with floor boundary, but safety reset
    if (player.position.y > worldHeight + 100) {
      if (_currentDungeon != null) {
        player.position = _currentDungeon!.playerSpawn.copy();
      } else {
        player.position = Vector2(200, 300);
      }
      player.velocity = Vector2.zero();
      player.takeDamage(10); // Small penalty for falling
    }
  }

  void _handleEnemyCollisions() {
    for (final enemy in enemies) {
      if (enemy.isDead) continue;

      // Ground collision for enemies
      for (final platform in platforms) {
        final platRect = platform.rect;
        final enemyFeet = Rect.fromLTWH(
          enemy.position.x - enemy.width / 2 + 4,
          enemy.position.y + enemy.height / 2 - 4,
          enemy.width - 8,
          8,
        );

        if (enemy.velocity.y >= 0 && enemyFeet.overlaps(platRect)) {
          enemy.position.y = platform.top - enemy.height / 2;
          enemy.velocity.y = 0;
        }
      }

      // World bounds
      if (enemy.position.x < enemy.width / 2) {
        enemy.position.x = enemy.width / 2;
      }
      if (enemy.position.x > worldWidth - enemy.width / 2) {
        enemy.position.x = worldWidth - enemy.width / 2;
      }

      // Fall off bottom - respawn at top
      if (enemy.position.y > worldHeight + 100) {
        enemy.position.y = 100;
      }
    }
  }

  void setViewportSize(double width, double height) {
    camera.setViewportSize(width, height);
  }
}
