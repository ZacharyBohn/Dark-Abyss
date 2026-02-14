import 'package:shared_preferences/shared_preferences.dart';

import 'currency_manager.dart';

/// Handles persistent storage for game data
class SaveSystem {
  static const String _goldKey = 'player_gold';
  static const String _essenceKey = 'player_essence';
  static const String _highestFloorKey = 'highest_floor';
  static const String _checkpointFloorKey = 'checkpoint_floor';
  static const String _upgradesKey = 'upgrades';
  static const String _unlockedSpellsKey = 'unlocked_spells';

  SharedPreferences? _prefs;
  bool _initialized = false;

  bool get isInitialized => _initialized;

  /// Initialize the save system (must be called before use)
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
  }

  /// Save currency data
  Future<void> saveCurrency(CurrencyManager currency) async {
    if (!_initialized || _prefs == null) return;

    await _prefs!.setInt(_goldKey, currency.gold);
    await _prefs!.setInt(_essenceKey, currency.essence);
  }

  /// Load currency data into a CurrencyManager
  void loadCurrency(CurrencyManager currency) {
    if (!_initialized || _prefs == null) return;

    final gold = _prefs!.getInt(_goldKey) ?? 0;
    final essence = _prefs!.getInt(_essenceKey) ?? 0;
    currency.loadFromSave(gold, essence);
  }

  /// Save the highest floor reached
  Future<void> saveHighestFloor(int floor) async {
    if (!_initialized || _prefs == null) return;

    final current = _prefs!.getInt(_highestFloorKey) ?? 0;
    if (floor > current) {
      await _prefs!.setInt(_highestFloorKey, floor);
    }
  }

  /// Get the highest floor reached
  int getHighestFloor() {
    if (!_initialized || _prefs == null) return 1;
    return _prefs!.getInt(_highestFloorKey) ?? 1;
  }

  /// Save the dungeon checkpoint floor (where next run starts)
  Future<void> saveCheckpointFloor(int floor) async {
    if (!_initialized || _prefs == null) return;
    await _prefs!.setInt(_checkpointFloorKey, floor);
  }

  /// Get the dungeon checkpoint floor
  int getCheckpointFloor() {
    if (!_initialized || _prefs == null) return 1;
    return _prefs!.getInt(_checkpointFloorKey) ?? 1;
  }

  /// Save purchased upgrades as comma-separated "id:tier" pairs
  Future<void> saveUpgrades(Map<String, int> upgrades) async {
    if (!_initialized || _prefs == null) return;
    final encoded = upgrades.entries
        .map((e) => '${e.key}:${e.value}')
        .join(',');
    await _prefs!.setString(_upgradesKey, encoded);
  }

  /// Load purchased upgrades
  Map<String, int> loadUpgrades() {
    if (!_initialized || _prefs == null) return {};
    final raw = _prefs!.getString(_upgradesKey);
    if (raw == null || raw.isEmpty) return {};
    final result = <String, int>{};
    for (final pair in raw.split(',')) {
      final parts = pair.split(':');
      if (parts.length == 2) {
        result[parts[0]] = int.tryParse(parts[1]) ?? 0;
      }
    }
    return result;
  }

  /// Save unlocked spells as comma-separated list
  Future<void> saveUnlockedSpells(List<String> spells) async {
    if (!_initialized || _prefs == null) return;
    await _prefs!.setStringList(_unlockedSpellsKey, spells);
  }

  /// Load unlocked spells
  List<String> loadUnlockedSpells() {
    if (!_initialized || _prefs == null) return [];
    return _prefs!.getStringList(_unlockedSpellsKey) ?? [];
  }

  /// Clear all save data (for testing or reset)
  Future<void> clearAll() async {
    if (!_initialized || _prefs == null) return;

    await _prefs!.remove(_goldKey);
    await _prefs!.remove(_essenceKey);
    await _prefs!.remove(_highestFloorKey);
    await _prefs!.remove(_checkpointFloorKey);
    await _prefs!.remove(_upgradesKey);
    await _prefs!.remove(_unlockedSpellsKey);
  }
}
