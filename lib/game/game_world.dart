import 'dart:ui';

import '../audio/audio_manager.dart';
import '../combat/combat_system.dart';
import '../data/constants.dart';
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
import '../ui/menu_system.dart';
import '../upgrades/upgrade_manager.dart';
import '../utils/math_utils.dart';
import 'camera.dart';
import 'game_state.dart';
import 'input_handler.dart';

enum _TransitionType {
  nextFloor,
  enterDungeon,
  returnToHub,
  hubReturn, // Voluntary return via checkpoint portal (no gold loss)
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
  ExitPortal? hubReturnPortal; // Checkpoint portal (appears every N floors)

  // Dungeon progress
  int dungeonCheckpointFloor = 1; // Floor to start next run on

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

  // Upgrade system
  final UpgradeManager upgradeManager = UpgradeManager();
  MenuState? activeMenu;

  GameWorld() {
    // Wire up currency manager to combat system
    combat.currencyManager = currencyManager;

    // Auto-save when currency changes
    currencyManager.onCurrencyChanged = _saveCurrency;

    // Auto-save when upgrades change
    upgradeManager.onUpgradesChanged = _saveUpgrades;

    // Start on start screen instead of hub (music will start when player enters hub)
    gameState = GameState.startScreen;
  }

  /// Initialize async components (call from game screen)
  Future<void> initializeAsync() async {
    await saveSystem.initialize();
    saveSystem.loadCurrency(currencyManager);
    dungeonCheckpointFloor = saveSystem.getCheckpointFloor();
    upgradeManager.loadFromSave(saveSystem.loadUpgrades());
  }

  void _saveCurrency() {
    if (saveSystem.isInitialized) {
      saveSystem.saveCurrency(currencyManager);
    }
  }

  void _saveUpgrades() {
    if (saveSystem.isInitialized) {
      saveSystem.saveUpgrades(upgradeManager.toSaveData());
    }
  }

  void _loadHub() {
    gameState = GameState.hub;
    currentFloor = 0;
    _deathHandled = false;
    hubReturnPortal = null;
    activeMenu = null;

    _hubRoom = HubRoom.generate();

    platforms = List.from(_hubRoom!.platforms);
    enemies = [];
    pickups = [];
    vendors = List.from(_hubRoom!.vendors);

    worldWidth = HubRoom.hubWidth;
    worldHeight = HubRoom.hubHeight;

    player = Player(position: _hubRoom!.spawnPoint.copy());

    // Apply upgrades to player in hub
    upgradeManager.applyUpgrades(player);

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

  /// Voluntary return to hub via checkpoint portal (no gold loss, saves progress)
  void _voluntaryHubReturn() {
    // Award floor completion bonus before leaving
    final bonus = LootTable.getFloorCompletionBonus(currentFloor);
    currencyManager.addGold(bonus);

    // Save checkpoint so next run starts on the next floor
    dungeonCheckpointFloor = currentFloor + 1;
    saveSystem.saveCheckpointFloor(dungeonCheckpointFloor);
    saveSystem.saveHighestFloor(currentFloor);

    isTransitioning = true;
    transitionDuration = 1.0;
    transitionTimer = 1.0;
    _pendingTransition = _TransitionType.hubReturn;
  }

  /// Whether this floor has a checkpoint (hub return) portal
  bool get isCheckpointFloor =>
      currentFloor > 0 && currentFloor % checkpointFloorInterval == 0;

  /// Text to display during transitions (used by game painter)
  String get transitionText {
    switch (_pendingTransition) {
      case _TransitionType.enterDungeon:
        return 'Entering the Abyss...';
      case _TransitionType.returnToHub:
        return 'Returning to Hub...';
      case _TransitionType.hubReturn:
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

    // Apply upgrades to player
    upgradeManager.applyUpgrades(player);

    // Create exit portal
    exitPortal = ExitPortal(position: _currentDungeon!.exitPosition.copy());
    exitPortal!.isUnlocked = false;

    // On checkpoint floors, create a hub return portal offset from exit
    if (floor % checkpointFloorInterval == 0) {
      hubReturnPortal = ExitPortal(
        position: Vector2(
          _currentDungeon!.exitPosition.x - 120,
          _currentDungeon!.exitPosition.y,
        ),
      );
      hubReturnPortal!.isUnlocked = false;
    } else {
      hubReturnPortal = null;
    }
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
        _generateFloor(dungeonCheckpointFloor);
        camera.snapTo(player.position);
        AudioManager().playDungeonMusic();
        break;
      case _TransitionType.returnToHub:
        _loadHub();
        AudioManager().playHubMusic();
        break;
      case _TransitionType.hubReturn:
        _loadHub();
        AudioManager().playHubMusic();
        break;
    }
  }

  void handleInput(InputState input, double dt) {
    // Start screen - any key press starts the game
    if (gameState == GameState.startScreen) {
      // Check if any key is pressed
      final anyKeyPressed =
          input.jumpPressed ||
          input.dashPressed ||
          input.attackPressed ||
          input.interactPressed ||
          input.up ||
          input.down ||
          input.left ||
          input.right ||
          input.escapePressed;

      if (anyKeyPressed) {
        _loadHub();
        AudioManager().playHubMusic();
      }
      return; // Don't process other input on start screen
    }

    if (player.isDead) return;

    // Menu state - route input to menu
    if (gameState == GameState.menu && activeMenu != null) {
      activeMenu!.handleInput(input);
      activeMenu!.update(input, dt);

      // Handle escape - close menu
      if (activeMenu!.requestClose) {
        gameState = GameState.hub;
        activeMenu = null;
      }
      // Handle purchase
      else if (activeMenu!.requestPurchase) {
        final upgrade = activeMenu!.selectedUpgrade;
        if (upgradeManager.purchase(upgrade, currencyManager)) {
          // Purchase succeeded, apply upgrades to player
          upgradeManager.applyUpgrades(player);
        }
        activeMenu!.requestPurchase = false;
      }

      return; // Don't process player input when in menu
    }

    player.handleInput(input, dt);

    // Hub interactions
    if (gameState == GameState.hub &&
        !isTransitioning &&
        (input.interactPressed || input.interact)) {
      // Dungeon portal interaction
      if (exitPortal != null && exitPortal!.isPlayerInRange(player.position)) {
        _enterDungeon();
        return;
      }

      // Vendor interaction
      for (final vendor in vendors) {
        if (vendor.isPlayerInRange(player.position)) {
          // Open vendor menu
          gameState = GameState.menu;
          activeMenu = MenuState(vendorType: vendor.type);
          return;
        }
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

    // Don't update game logic on start screen or in menu
    if (gameState == GameState.startScreen || gameState == GameState.menu) {
      return;
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
        // Dungeon: unlock portals when all enemies are defeated
        if (!exitPortal!.isUnlocked && enemies.isEmpty) {
          exitPortal!.isUnlocked = true;
          if (hubReturnPortal != null) {
            hubReturnPortal!.isUnlocked = true;
          }
        }

        // Check if player enters unlocked exit portal
        if (exitPortal!.isUnlocked &&
            exitPortal!.isPlayerInRange(player.position)) {
          _goToNextFloor();
        }

        // Check if player enters unlocked hub return portal
        if (hubReturnPortal != null &&
            hubReturnPortal!.isUnlocked &&
            hubReturnPortal!.isPlayerInRange(player.position)) {
          _voluntaryHubReturn();
        }
      }
      // Hub portal interaction is handled in handleInput()
    }

    // Update hub return portal
    if (hubReturnPortal != null) {
      hubReturnPortal!.update(dt);
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
        // Check if player was above platform (prevents clipping from below)
        final wasAbovePlatform =
            player.position.y + player.height / 2 - player.velocity.y * 0.017 <=
            platform.top + 10;

        if (wasAbovePlatform) {
          // One-way platforms: allow drop-through when holding down
          if (platform.isOneWay && player.isDropping) {
            continue; // Skip collision - player is dropping through
          }

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
