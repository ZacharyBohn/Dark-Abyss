import '../entities/player.dart';
import '../game/game_world.dart';
import 'projectile.dart';
import 'spell.dart';

class SpellManager {
  // Equipped spells (max 3 slots)
  final List<Spell?> equippedSpells = [null, null, null];

  // Unlocked spells (available for purchase/equipping)
  final Set<SpellType> unlockedSpells = {};

  // Active projectiles
  final List<Projectile> projectiles = [];

  SpellManager();

  /// Unlock a spell (via purchase)
  void unlockSpell(SpellType type) {
    unlockedSpells.add(type);
  }

  /// Check if a spell is unlocked
  bool isUnlocked(SpellType type) {
    return unlockedSpells.contains(type);
  }

  /// Equip a spell to a slot (0-2)
  void equipSpell(Spell spell, int slot) {
    if (slot >= 0 && slot < 3) {
      equippedSpells[slot] = spell;
    }
  }

  /// Unequip a spell from a slot
  void unequipSpell(int slot) {
    if (slot >= 0 && slot < 3) {
      equippedSpells[slot] = null;
    }
  }

  /// Cast spell from slot
  void castSpell(int slot, Player player, GameWorld world) {
    if (slot >= 0 && slot < 3 && equippedSpells[slot] != null) {
      equippedSpells[slot]!.startCast(player, world);
    }
  }

  /// Add a projectile to the active list
  void addProjectile(Projectile projectile) {
    projectiles.add(projectile);
  }

  /// Update all spells and projectiles
  void update(double dt, Player player, GameWorld world) {
    // Update equipped spells (cooldowns, casting)
    for (var spell in equippedSpells) {
      spell?.update(dt, player, world);
    }

    // Update projectiles
    for (var i = projectiles.length - 1; i >= 0; i--) {
      projectiles[i].update(dt);

      // Remove dead projectiles
      if (projectiles[i].isDead) {
        projectiles.removeAt(i);
      }
    }
  }

  /// Get spell from slot
  Spell? getSpell(int slot) {
    if (slot >= 0 && slot < 3) {
      return equippedSpells[slot];
    }
    return null;
  }

  /// Clear all projectiles (e.g., on floor transition)
  void clearProjectiles() {
    projectiles.clear();
  }

  /// Reset all spell cooldowns
  void resetCooldowns() {
    for (var spell in equippedSpells) {
      if (spell != null) {
        spell.currentCooldown = 0;
        spell.isCasting = false;
        spell.castTimer = 0;
      }
    }
  }

  /// Serialize unlocked spells for saving
  List<String> serializeUnlockedSpells() {
    return unlockedSpells.map((e) => e.toString()).toList();
  }

  /// Deserialize unlocked spells from save
  void deserializeUnlockedSpells(List<String> data) {
    unlockedSpells.clear();
    for (var typeStr in data) {
      try {
        final type = SpellType.values.firstWhere(
          (e) => e.toString() == typeStr,
        );
        unlockedSpells.add(type);
      } catch (e) {
        // Skip invalid spell types
      }
    }
  }
}
