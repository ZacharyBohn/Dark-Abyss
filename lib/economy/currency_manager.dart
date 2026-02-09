/// Manages player currency (gold and essence)
/// Gold: Used for stat upgrades, drops from enemies
/// Essence: Rare currency for ability unlocks, drops from elite enemies/bosses
class CurrencyManager {
  int _gold = 0;
  int _essence = 0;

  // Session tracking (gold earned this run, lost on death)
  int _sessionGold = 0;

  // Callbacks for save system
  void Function()? onCurrencyChanged;

  int get gold => _gold;
  int get essence => _essence;
  int get sessionGold => _sessionGold;

  /// Add gold (from pickups, floor bonuses)
  void addGold(int amount) {
    if (amount <= 0) return;
    _gold += amount;
    _sessionGold += amount;
    onCurrencyChanged?.call();
  }

  /// Add essence (from rare drops)
  void addEssence(int amount) {
    if (amount <= 0) return;
    _essence += amount;
    onCurrencyChanged?.call();
  }

  /// Spend gold (for purchases)
  /// Returns true if successful, false if insufficient funds
  bool spendGold(int amount) {
    if (amount <= 0) return false;
    if (_gold < amount) return false;
    _gold -= amount;
    onCurrencyChanged?.call();
    return true;
  }

  /// Spend essence (for ability unlocks)
  /// Returns true if successful, false if insufficient funds
  bool spendEssence(int amount) {
    if (amount <= 0) return false;
    if (_essence < amount) return false;
    _essence -= amount;
    onCurrencyChanged?.call();
    return true;
  }

  /// Check if player can afford a gold cost
  bool canAffordGold(int amount) => _gold >= amount;

  /// Check if player can afford an essence cost
  bool canAffordEssence(int amount) => _essence >= amount;

  /// Called when player dies - lose percentage of session gold
  void onPlayerDeath({double lossPercent = 0.5}) {
    final lostGold = (_sessionGold * lossPercent).round();
    _gold = (_gold - lostGold).clamp(0, _gold);
    _sessionGold = 0;
    onCurrencyChanged?.call();
  }

  /// Called when starting a new dungeon run
  void onRunStart() {
    _sessionGold = 0;
  }

  /// Load currency from save data
  void loadFromSave(int gold, int essence) {
    _gold = gold;
    _essence = essence;
    _sessionGold = 0;
  }

  /// Reset all currency (for testing or new game)
  void reset() {
    _gold = 0;
    _essence = 0;
    _sessionGold = 0;
    onCurrencyChanged?.call();
  }
}
