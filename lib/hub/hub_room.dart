import '../dungeon/exit_portal.dart';
import '../dungeon/platform.dart';
import '../utils/math_utils.dart';
import 'vendor.dart';

class HubRoom {
  static const double hubWidth = 800.0;
  static const double hubHeight = 600.0;

  final List<Platform> platforms;
  final List<Vendor> vendors;
  final ExitPortal dungeonPortal;
  final Vector2 spawnPoint;

  HubRoom._({
    required this.platforms,
    required this.vendors,
    required this.dungeonPortal,
    required this.spawnPoint,
  });

  /// Generate the static hub layout
  factory HubRoom.generate() {
    final platforms = <Platform>[];
    final vendors = <Vendor>[];

    // === FLOOR ===
    platforms.add(Platform(
      x: 0,
      y: hubHeight - 40,
      width: hubWidth,
      height: 40,
      isOneWay: false, // Solid floor
    ));

    // === WALLS ===
    platforms.add(Platform(
      x: -20,
      y: 0,
      width: 20,
      height: hubHeight,
      isWall: true,
      isOneWay: false, // Solid wall
    ));
    platforms.add(Platform(
      x: hubWidth,
      y: 0,
      width: 20,
      height: hubHeight,
      isWall: true,
      isOneWay: false, // Solid wall
    ));

    // === CEILING ===
    platforms.add(Platform(
      x: 0,
      y: -20,
      width: hubWidth,
      height: 20,
      isOneWay: false, // Solid ceiling
    ));

    // === VENDOR PLATFORMS ===

    // Stat Vendor platform (left, upper area)
    const statPlatX = 80.0;
    final statPlatY = hubHeight * 0.40;
    platforms.add(Platform(
      x: statPlatX,
      y: statPlatY,
      width: 120,
      height: 20,
    ));

    // Spell Vendor platform (right, upper area)
    final spellPlatX = hubWidth - 200;
    final spellPlatY = hubHeight * 0.40;
    platforms.add(Platform(
      x: spellPlatX,
      y: spellPlatY,
      width: 120,
      height: 20,
    ));

    // Ability Vendor platform (center, mid area)
    final abilityPlatX = hubWidth / 2 - 60;
    final abilityPlatY = hubHeight * 0.55;
    platforms.add(Platform(
      x: abilityPlatX,
      y: abilityPlatY,
      width: 120,
      height: 20,
    ));

    // Dungeon portal platform (center, upper area)
    final portalPlatX = hubWidth / 2 - 80;
    final portalPlatY = hubHeight * 0.25;
    platforms.add(Platform(
      x: portalPlatX,
      y: portalPlatY,
      width: 160,
      height: 20,
    ));

    // === STEPPING PLATFORMS ===

    // Left stepping stone to stat vendor
    platforms.add(Platform(
      x: 60,
      y: hubHeight * 0.60,
      width: 100,
      height: 15,
    ));

    // Right stepping stone to spell vendor
    platforms.add(Platform(
      x: hubWidth - 160,
      y: hubHeight * 0.60,
      width: 100,
      height: 15,
    ));

    // Center stepping stone (lower)
    platforms.add(Platform(
      x: hubWidth / 2 - 50,
      y: hubHeight * 0.70,
      width: 100,
      height: 15,
    ));

    // Center stepping stone (mid - between ability vendor and portal)
    platforms.add(Platform(
      x: hubWidth / 2 - 40,
      y: hubHeight * 0.40,
      width: 80,
      height: 15,
    ));

    // === VENDORS ===
    vendors.add(Vendor(
      type: VendorType.stat,
      position: Vector2(statPlatX + 60, statPlatY - 25),
      name: 'STAT VENDOR',
    ));

    vendors.add(Vendor(
      type: VendorType.spell,
      position: Vector2(spellPlatX + 60, spellPlatY - 25),
      name: 'SPELL VENDOR',
    ));

    vendors.add(Vendor(
      type: VendorType.ability,
      position: Vector2(abilityPlatX + 60, abilityPlatY - 25),
      name: 'ABILITY VENDOR',
    ));

    // === DUNGEON PORTAL ===
    final dungeonPortal = ExitPortal(
      position: Vector2(hubWidth / 2, portalPlatY - 30),
    );
    dungeonPortal.isUnlocked = true; // Always accessible in hub

    return HubRoom._(
      platforms: platforms,
      vendors: vendors,
      dungeonPortal: dungeonPortal,
      spawnPoint: Vector2(hubWidth / 2, hubHeight - 80),
    );
  }
}
