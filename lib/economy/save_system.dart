import 'package:shared_preferences/shared_preferences.dart';

import 'currency_manager.dart';

/// Handles persistent storage for game data
class SaveSystem {
  static const String _goldKey = 'player_gold';
  static const String _essenceKey = 'player_essence';
  static const String _highestFloorKey = 'highest_floor';

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

  /// Clear all save data (for testing or reset)
  Future<void> clearAll() async {
    if (!_initialized || _prefs == null) return;

    await _prefs!.remove(_goldKey);
    await _prefs!.remove(_essenceKey);
    await _prefs!.remove(_highestFloorKey);
  }
}
