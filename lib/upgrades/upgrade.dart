import '../hub/vendor.dart';

/// Categories of upgrades, mapped to vendor types
enum UpgradeCategory { stat, ability, spell }

/// Maps vendor types to upgrade categories
UpgradeCategory categoryForVendor(VendorType type) {
  switch (type) {
    case VendorType.stat:
      return UpgradeCategory.stat;
    case VendorType.ability:
      return UpgradeCategory.ability;
    case VendorType.spell:
      return UpgradeCategory.spell;
  }
}

/// Cost for a single tier of an upgrade
class UpgradeCost {
  final int gold;
  final int essence;

  const UpgradeCost({this.gold = 0, this.essence = 0});
}

/// Definition of a single upgrade
class Upgrade {
  final String id;
  final String name;
  final String description;
  final UpgradeCategory category;
  final int maxTier;
  final List<UpgradeCost> tierCosts; // One per tier

  const Upgrade({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.maxTier,
    required this.tierCosts,
  });
}

/// All upgrade definitions
class Upgrades {
  // Stat upgrades (gold)
  static const vitality = Upgrade(
    id: 'vitality',
    name: 'Vitality',
    description: '+20 max HP',
    category: UpgradeCategory.stat,
    maxTier: 5,
    tierCosts: [
      UpgradeCost(gold: 50),
      UpgradeCost(gold: 100),
      UpgradeCost(gold: 200),
      UpgradeCost(gold: 400),
      UpgradeCost(gold: 800),
    ],
  );

  static const power = Upgrade(
    id: 'power',
    name: 'Power',
    description: '+10% attack damage',
    category: UpgradeCategory.stat,
    maxTier: 5,
    tierCosts: [
      UpgradeCost(gold: 75),
      UpgradeCost(gold: 150),
      UpgradeCost(gold: 300),
      UpgradeCost(gold: 600),
      UpgradeCost(gold: 1200),
    ],
  );

  static const agility = Upgrade(
    id: 'agility',
    name: 'Agility',
    description: '+5% move speed',
    category: UpgradeCategory.stat,
    maxTier: 3,
    tierCosts: [
      UpgradeCost(gold: 100),
      UpgradeCost(gold: 250),
      UpgradeCost(gold: 500),
    ],
  );

  static const endurance = Upgrade(
    id: 'endurance',
    name: 'Endurance',
    description: '+1 max dash',
    category: UpgradeCategory.stat,
    maxTier: 3,
    tierCosts: [
      UpgradeCost(gold: 200),
      UpgradeCost(gold: 500),
      UpgradeCost(gold: 1000),
    ],
  );

  static const recovery = Upgrade(
    id: 'recovery',
    name: 'Recovery',
    description: '+20% energy regen',
    category: UpgradeCategory.stat,
    maxTier: 3,
    tierCosts: [
      UpgradeCost(gold: 150),
      UpgradeCost(gold: 350),
      UpgradeCost(gold: 700),
    ],
  );

  // Ability upgrades (essence)
  static const doubleJump = Upgrade(
    id: 'double_jump',
    name: 'Double Jump',
    description: 'Jump again in mid-air',
    category: UpgradeCategory.ability,
    maxTier: 1,
    tierCosts: [UpgradeCost(essence: 5)],
  );

  static const airDash = Upgrade(
    id: 'air_dash',
    name: 'Air Dash',
    description: 'Dash while airborne',
    category: UpgradeCategory.ability,
    maxTier: 1,
    tierCosts: [UpgradeCost(essence: 8)],
  );

  static const comboMaster = Upgrade(
    id: 'combo_master',
    name: 'Combo Master',
    description: '4th combo hit, +50% damage',
    category: UpgradeCategory.ability,
    maxTier: 1,
    tierCosts: [UpgradeCost(essence: 10)],
  );

  static const lifeSteal = Upgrade(
    id: 'life_steal',
    name: 'Life Steal',
    description: '5% of damage heals you',
    category: UpgradeCategory.ability,
    maxTier: 1,
    tierCosts: [UpgradeCost(essence: 15)],
  );

  static const criticalStrike = Upgrade(
    id: 'critical_strike',
    name: 'Critical Strike',
    description: '15% chance for 2x damage',
    category: UpgradeCategory.ability,
    maxTier: 1,
    tierCosts: [UpgradeCost(essence: 12)],
  );

  // Spell upgrades (coming in Phase 8)
  static const fireball = Upgrade(
    id: 'fireball',
    name: 'Fireball',
    description: 'Coming soon...',
    category: UpgradeCategory.spell,
    maxTier: 1,
    tierCosts: [UpgradeCost(gold: 200, essence: 3)],
  );

  static const frostNova = Upgrade(
    id: 'frost_nova',
    name: 'Frost Nova',
    description: 'Coming soon...',
    category: UpgradeCategory.spell,
    maxTier: 1,
    tierCosts: [UpgradeCost(gold: 300, essence: 5)],
  );

  static const soulDrain = Upgrade(
    id: 'soul_drain',
    name: 'Soul Drain',
    description: 'Coming soon...',
    category: UpgradeCategory.spell,
    maxTier: 1,
    tierCosts: [UpgradeCost(gold: 250, essence: 4)],
  );

  /// All upgrades indexed by category
  static List<Upgrade> forCategory(UpgradeCategory category) {
    switch (category) {
      case UpgradeCategory.stat:
        return [vitality, power, agility, endurance, recovery];
      case UpgradeCategory.ability:
        return [doubleJump, airDash, comboMaster, lifeSteal, criticalStrike];
      case UpgradeCategory.spell:
        return [fireball, frostNova, soulDrain];
    }
  }

  static final all = [
    vitality, power, agility, endurance, recovery,
    doubleJump, airDash, comboMaster, lifeSteal, criticalStrike,
    fireball, frostNova, soulDrain,
  ];
}
