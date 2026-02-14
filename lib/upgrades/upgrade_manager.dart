import '../data/constants.dart';
import '../economy/currency_manager.dart';
import '../entities/player.dart';
import 'upgrade.dart';

/// Tracks purchased upgrades and applies them to the player
class UpgradeManager {
  /// Upgrade ID → purchased tier (0 = not purchased)
  final Map<String, int> _purchased = {};

  /// Callback when upgrades change (for saving)
  void Function()? onUpgradesChanged;

  /// Get current tier for an upgrade
  int getTier(String upgradeId) => _purchased[upgradeId] ?? 0;

  /// Whether an upgrade is at max tier
  bool isMaxed(Upgrade upgrade) => getTier(upgrade.id) >= upgrade.maxTier;

  /// Get the cost of the next tier for an upgrade (null if maxed)
  UpgradeCost? getNextCost(Upgrade upgrade) {
    final tier = getTier(upgrade.id);
    if (tier >= upgrade.maxTier) return null;
    return upgrade.tierCosts[tier];
  }

  /// Check if player can afford the next tier
  bool canPurchase(Upgrade upgrade, CurrencyManager currency) {
    final cost = getNextCost(upgrade);
    if (cost == null) return false;
    // Spell upgrades are locked until Phase 8
    if (upgrade.category == UpgradeCategory.spell) return false;
    return currency.canAffordGold(cost.gold) &&
        currency.canAffordEssence(cost.essence);
  }

  /// Purchase the next tier of an upgrade. Returns true if successful.
  bool purchase(Upgrade upgrade, CurrencyManager currency) {
    if (!canPurchase(upgrade, currency)) return false;
    final cost = getNextCost(upgrade)!;

    // Deduct costs
    if (cost.gold > 0 && !currency.spendGold(cost.gold)) return false;
    if (cost.essence > 0 && !currency.spendEssence(cost.essence)) {
      // Refund gold if essence spend fails
      currency.addGold(cost.gold);
      return false;
    }

    _purchased[upgrade.id] = getTier(upgrade.id) + 1;
    onUpgradesChanged?.call();
    return true;
  }

  /// Apply all owned upgrades to a player (call when entering dungeon or hub)
  void applyUpgrades(Player player) {
    // Reset to base stats first
    player.maxHP = playerBaseHP;
    player.atk = playerBaseATK;
    player.def = playerBaseDEF;
    player.spd = playerBaseSPD;
    player.maxJumps = 1;
    player.canAirDash = false;
    player.maxCombo = 3;
    player.lifeStealPercent = 0;
    player.critChance = 0;
    player.critMultiplier = 2.0;
    player.attackMultiplier = 1.0;
    player.energyRegenRate = 1.0;
    player.dashCooldownMultiplier = 1.0;

    // Apply stat upgrades
    final vitalityTier = getTier('vitality');
    if (vitalityTier > 0) {
      player.maxHP += vitalityTier * 20.0;
    }

    final powerTier = getTier('power');
    if (powerTier > 0) {
      player.attackMultiplier += powerTier * 0.10;
    }

    final agilityTier = getTier('agility');
    if (agilityTier > 0) {
      player.spd += agilityTier * 0.05;
    }

    // Endurance: not applying dash charges yet (would need dash charge system)
    // For now, reduce dash cooldown instead
    final enduranceTier = getTier('endurance');
    if (enduranceTier > 0) {
      player.dashCooldownMultiplier = 1.0 - enduranceTier * 0.2;
    }

    final recoveryTier = getTier('recovery');
    if (recoveryTier > 0) {
      player.energyRegenRate += recoveryTier * 0.20;
    }

    // Apply ability upgrades
    if (getTier('double_jump') > 0) {
      player.maxJumps = 2;
    }

    if (getTier('air_dash') > 0) {
      player.canAirDash = true;
    }

    if (getTier('combo_master') > 0) {
      player.maxCombo = 4;
      player.attackMultiplier += 0.5; // +50% on the 4th hit handled differently, but general boost
    }

    if (getTier('life_steal') > 0) {
      player.lifeStealPercent = 0.05;
    }

    if (getTier('critical_strike') > 0) {
      player.critChance = 0.15;
      player.critMultiplier = 2.0;
    }

    // Ensure current HP doesn't exceed new max (but also heal to new max in hub)
    player.currentHP = player.maxHP;
  }

  /// Serialize for saving
  Map<String, int> toSaveData() => Map.from(_purchased);

  /// Load from save data
  void loadFromSave(Map<String, int> data) {
    _purchased.clear();
    _purchased.addAll(data);
  }
}
