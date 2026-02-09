import 'dart:ui';

import '../combat/combat_system.dart';
import '../dungeon/exit_portal.dart';
import '../dungeon/floor_generator.dart';
import '../dungeon/platform.dart';
import '../dungeon/room.dart';
import '../economy/currency_manager.dart';
import '../economy/loot_table.dart';
import '../economy/save_system.dart';
import '../entities/enemy.dart';
import '../entities/pickup.dart';
import '../entities/player.dart';
import '../hub/hub_room.dart';
import '../hub/vendor.dart';
import '../utils/math_utils.dart';
import 'camera.dart';
import 'game_state.dart';
import 'input_handler.dart';

enum _TransitionType {
  nextFloor,
  enterDungeon,
  returnToHub,
}

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

  // Economy
  final CurrencyManager currencyManager = CurrencyManager();
  final SaveSystem saveSystem = SaveSystem();

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

  // Game state
  GameState gameState = GameState.hub;

  // Hub
  HubRoom? _hubRoom;
  List<Vendor> vendors = [];

  // Floor transition
  bool isTransitioning = false;
  double transitionTimer = 0;
  double transitionDuration = 1.0;
  _TransitionType _pendingTransition = _TransitionType.nextFloor;

  // Death handling
  bool _deathHandled = false;
  double _deathTimer = 0;
  static const double _deathDelay = 1.5;

  GameWorld() {
    // Wire up currency manager to combat system
    combat.currencyManager = currencyManager;

    // Auto-save when currency changes
    currencyManager.onCurrencyChanged = _saveCurrency;

    _loadHub();
  }

  /// Initialize async components (call from game screen)
  Future<void> initializeAsync() async {
    await saveSystem.initialize();
    saveSystem.loadCurrency(currencyManager);
  }

  void _saveCurrency() {
    if (saveSystem.isInitialized) {
      saveSystem.saveCurrency(currencyManager);
    }
  }

  void _loadHub() {
    gameState = GameState.hub;
    currentFloor = 0;
    _deathHandled = false;

    _hubRoom = HubRoom.generate();

    platforms = List.from(_hubRoom!.platforms);
    enemies = [];
    pickups = [];
    vendors = List.from(_hubRoom!.vendors);

    worldWidth = HubRoom.hubWidth;
    worldHeight = HubRoom.hubHeight;

    player = Player(position: _hubRoom!.spawnPoint.copy());

    exitPortal = _hubRoom!.dungeonPortal;

    combat.clear();
    camera.snapTo(player.position);
  }

  void _enterDungeon() {
    currencyManager.onRunStart();
    isTransitioning = true;
    transitionDuration = 0.6;
    transitionTimer = 0.6;
    _pendingTransition = _TransitionType.enterDungeon;
  }

  void _returnToHub() {
    currencyManager.onPlayerDeath();
    saveSystem.saveHighestFloor(currentFloor);
    isTransitioning = true;
    transitionDuration = 1.5;
    transitionTimer = 1.5;
    _pendingTransition = _TransitionType.returnToHub;
  }

  /// Text to display during transitions (used by game painter)
  String get transitionText {
    switch (_pendingTransition) {
      case _TransitionType.enterDungeon:
        return 'Entering the Abyss...';
      case _TransitionType.returnToHub:
        return 'Returning to Hub...';
      case _TransitionType.nextFloor:
        return 'Floor ${currentFloor + 1}';
    }
  }

  void _generateFloor(int floor) {
    currentFloor = floor;

    // Generate dungeon
    _currentDungeon = _floorGenerator.generate(floor);

    // Set up world from dungeon
    platforms = List.from(_currentDungeon!.allPlatforms);
    enemies = List.from(_currentDungeon!.allEnemies);
    pickups = [];

    // Set floor number on all enemies for loot scaling
    for (final enemy in enemies) {
      enemy.currentFloor = floor;
    }

    worldWidth = _currentDungeon!.totalWidth;
    worldHeight = _currentDungeon!.totalHeight;

    // Create player at spawn point
    player = Player(position: _currentDungeon!.playerSpawn.copy());

    // Create exit portal
    exitPortal = ExitPortal(position: _currentDungeon!.exitPosition.copy());
    exitPortal!.isUnlocked = false;
  }

  void _goToNextFloor() {
    // Award floor completion bonus
    final bonus = LootTable.getFloorCompletionBonus(currentFloor);
    currencyManager.addGold(bonus);

    isTransitioning = true;
    transitionDuration = 1.0;
    transitionTimer = 1.0;
    _pendingTransition = _TransitionType.nextFloor;
  }

  void _completeTransition() {
    isTransitioning = false;
    switch (_pendingTransition) {
      case _TransitionType.nextFloor:
        _generateFloor(currentFloor + 1);
        camera.snapTo(player.position);
        break;
      case _TransitionType.enterDungeon:
        gameState = GameState.dungeon;
        _generateFloor(1);
        camera.snapTo(player.position);
        break;
      case _TransitionType.returnToHub:
        _loadHub();
        break;
    }
  }

  void handleInput(InputState input, double dt) {
    if (player.isDead) return;

    player.handleInput(input, dt);

    // Hub portal interaction (check held state too so holding E works reliably)
    if (gameState == GameState.hub && !isTransitioning &&
        (input.interactPressed || input.interact)) {
      if (exitPortal != null && exitPortal!.isPlayerInRange(player.position)) {
        _enterDungeon();
      }
    }
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

    // Handle player death (dungeon only)
    if (gameState == GameState.dungeon && player.isDead && !_deathHandled) {
      _deathHandled = true;
      _deathTimer = _deathDelay;
    }
    if (_deathHandled) {
      _deathTimer -= dt;
      combat.update(dt); // Keep particles/numbers animating
      if (_deathTimer <= 0) {
        _deathHandled = false;
        _returnToHub();
      }
      return;
    }

    // Update player
    player.update(dt);

    // Update vendors (hub only)
    if (gameState == GameState.hub) {
      for (final vendor in vendors) {
        vendor.update(dt);
      }
    }

    // Update enemies
    for (final enemy in enemies) {
      enemy.targetPosition = player.position;
      enemy.platforms = platforms;
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

      if (gameState == GameState.dungeon) {
        // Dungeon: unlock portal when all enemies are defeated
        if (!exitPortal!.isUnlocked && enemies.isEmpty) {
          exitPortal!.isUnlocked = true;
        }

        // Check if player enters unlocked portal
        if (exitPortal!.isUnlocked &&
            exitPortal!.isPlayerInRange(player.position)) {
          _goToNextFloor();
        }
      }
      // Hub portal interaction is handled in handleInput()
    }

    // Handle collisions
    _handleCollisions();
    if (gameState == GameState.dungeon) {
      _handleEnemyCollisions();
    }

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
