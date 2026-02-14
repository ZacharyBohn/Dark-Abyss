import '../game/input_handler.dart';
import '../hub/vendor.dart';
import '../upgrades/upgrade.dart';

/// Tracks the state of the upgrade menu
class MenuState {
  final VendorType vendorType;
  final List<Upgrade> upgrades;
  int selectedIndex = 0;
  bool requestClose = false;
  bool requestPurchase = false;

  MenuState({required this.vendorType})
      : upgrades = Upgrades.forCategory(categoryForVendor(vendorType));

  Upgrade get selectedUpgrade => upgrades[selectedIndex];

  /// Process input for menu navigation. Returns true if input was consumed.
  bool handleInput(InputState input) {
    if (input.escapePressed) {
      requestClose = true;
      return true;
    }

    // Navigate up/down
    if (input.jumpPressed) {
      // Up (W/Up also works via jump)
    }
    if (input.up && !input.down) {
      // Handled below via pressed flags
    }

    // Use raw directional pressed detection:
    // Since we don't have upPressed/downPressed, we use a simple approach
    // Move selection with W/S or Up/Down
    if (input.interactPressed || input.attackPressed) {
      requestPurchase = true;
      return true;
    }

    return false;
  }

  /// Call each frame with dt to handle held-key navigation
  void update(InputState input, double dt) {
    _navAccumulator += dt;
    if (_navAccumulator < _navDelay) return;

    bool moved = false;
    if (input.up && !input.down) {
      selectedIndex--;
      moved = true;
    } else if (input.down && !input.up) {
      selectedIndex++;
      moved = true;
    }

    if (moved) {
      // Wrap around
      if (selectedIndex < 0) selectedIndex = upgrades.length - 1;
      if (selectedIndex >= upgrades.length) selectedIndex = 0;
      _navAccumulator = 0;
      // Slow down initial repeat
      _navDelay = _hasMovedOnce ? 0.12 : 0.2;
      _hasMovedOnce = true;
    }

    if (!input.up && !input.down) {
      _navAccumulator = 0;
      _navDelay = 0.0; // instant first press
      _hasMovedOnce = false;
    }
  }

  double _navAccumulator = 0;
  double _navDelay = 0.0;
  bool _hasMovedOnce = false;
}
