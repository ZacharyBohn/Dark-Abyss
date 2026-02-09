import 'dart:math';

import '../entities/enemy.dart';

/// Drop definition for a pickup
class DropInfo {
  final PickupType type;
  final int value;

  const DropInfo(this.type, this.value);
}

/// Defines enemy loot drops and floor scaling
class LootTable {
  static final Random _random = Random();

  // Base gold drops by drifter shape type
  // 0 = triangle, 1 = square, 2 = pentagon
  static const List<int> _drifterGoldMin = [5, 10, 15];
  static const List<int> _drifterGoldMax = [10, 15, 25];

  // Essence drop chances by shape
  static const List<double> _drifterEssenceChance = [0.05, 0.10, 0.15];
  static const List<int> _drifterEssenceMin = [1, 1, 1];
  static const List<int> _drifterEssenceMax = [1, 1, 2];

  // Boss drops
  static const int bossGoldMin = 200;
  static const int bossGoldMax = 300;
  static const int bossEssenceMin = 10;
  static const int bossEssenceMax = 15;

  // Floor completion bonus
  static const int floorBonusBase = 25;
  static const double floorBonusScaling = 0.2; // +20% per floor

  /// Calculate floor gold scaling multiplier
  /// Gold scales: base * (1 + floor * 0.1)
  static double getFloorScaling(int floor) {
    return 1.0 + (floor - 1) * 0.1;
  }

  /// Get drops for a drifter enemy
  /// shapeType: 0 = triangle, 1 = square, 2 = pentagon
  static List<DropInfo> getDrifterDrops(int shapeType, int floor) {
    final drops = <DropInfo>[];
    final scaling = getFloorScaling(floor);

    // Clamp shape type
    final shape = shapeType.clamp(0, 2);

    // Always drop gold
    final baseGold = _random.nextInt(_drifterGoldMax[shape] - _drifterGoldMin[shape] + 1) +
        _drifterGoldMin[shape];
    final scaledGold = (baseGold * scaling).round();
    drops.add(DropInfo(PickupType.coin, scaledGold));

    // Chance for essence
    if (_random.nextDouble() < _drifterEssenceChance[shape]) {
      final essence = _random.nextInt(_drifterEssenceMax[shape] - _drifterEssenceMin[shape] + 1) +
          _drifterEssenceMin[shape];
      drops.add(DropInfo(PickupType.essence, essence));
    }

    // Small chance for health drop (10%)
    if (_random.nextDouble() < 0.10) {
      drops.add(const DropInfo(PickupType.health, 15));
    }

    // Energy drop (30%)
    if (_random.nextDouble() < 0.30) {
      drops.add(const DropInfo(PickupType.energy, 10));
    }

    return drops;
  }

  /// Get drops for a boss enemy
  static List<DropInfo> getBossDrops(int floor) {
    final drops = <DropInfo>[];
    final scaling = getFloorScaling(floor);

    // Guaranteed gold
    final baseGold = _random.nextInt(bossGoldMax - bossGoldMin + 1) + bossGoldMin;
    final scaledGold = (baseGold * scaling).round();
    drops.add(DropInfo(PickupType.coin, scaledGold));

    // Guaranteed essence
    final essence = _random.nextInt(bossEssenceMax - bossEssenceMin + 1) + bossEssenceMin;
    drops.add(DropInfo(PickupType.essence, essence));

    // Guaranteed health
    drops.add(const DropInfo(PickupType.health, 50));

    return drops;
  }

  /// Calculate floor completion bonus
  static int getFloorCompletionBonus(int floor) {
    return (floorBonusBase * (1.0 + floor * floorBonusScaling)).round();
  }
}
