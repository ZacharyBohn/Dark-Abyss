# Abyss Runner - Work Tracker

## Current Phase: Phase 8 - Magic System (COMPLETE)
## Current Status: READY TO BEGIN PHASE 9

## Upcoming Phases Overview
| Phase | Focus | Key Deliverable |
|-------|-------|-----------------|
| 5 | Currency & Economy | Gold/essence drops, HUD currency, persistence |
| 6 | Hub/Base Room | Safe hub area, vendor NPCs, game state flow |
| 7 | Upgrade System | Button-based menus, stat/ability purchases |
| 8 | Magic System | Mana, spells, projectiles, spell vendor |
| 9 | Complex Dungeons | Traps, arenas, chests, puzzles, mini-map |
| 10 | Boss Encounters | Phase-based boss fights every 5 floors |
| 11 | Polish & Balance | Economy tuning, stats screen, sound effects |

## Progress Checklist

### Phase 1: Foundation (Get something on screen)
- [x] 1. Create Flutter project structure
- [x] 2. Set up pubspec.yaml with shared_preferences
- [x] 3. Create constants.dart with all game tuning values
- [x] 4. Create math_utils.dart (Vector2 class, lerp, clamp)
- [x] 5. Build game_engine.dart — Ticker-based game loop
- [x] 6. Build game_screen.dart — CustomPaint widget that fills the screen
- [x] 7. Build game_painter.dart — empty painter that draws a dark background
- [x] 8. **TEST CHECKPOINT 1: PASSED**

### Phase 2: Player Movement
- [x] 9. Create entity.dart base class
- [x] 10. Create player.dart with full physics
- [x] 11. Create input_handler.dart for keyboard input
- [x] 12. Create player_renderer.dart (glowing diamond with afterimages)
- [x] 13. Add test platforms
- [x] 14. Implement: run, jump, gravity, land (with coyote time + jump buffer)
- [x] 15. Implement: dash mechanic (i-frames, afterimages, 8-directional)
- [x] 16. Implement: wall jump (wall slide, wall detection)
- [x] 17. Create camera.dart with smooth follow and look-ahead
- [x] 18. **TEST CHECKPOINT 2: PASSED**

### Phase 3: Combat
- [x] 19. Create enemy.dart base class with AI states
- [x] 20. Create drifter.dart (floating geometric enemy)
- [x] 21. Create pickup.dart (health, energy, coin, essence)
- [x] 22. Create combat_system.dart (hit detection, damage)
- [x] 23. Create damage_numbers.dart (floating damage text)
- [x] 24. Create particle_system.dart (hit sparks, death bursts)
- [x] 25. Create enemy_renderer.dart (drifter shapes with glow)
- [x] 26. Create effects_renderer.dart (particles, pickups, damage numbers)
- [x] 27. Add player attack with combo system
- [x] 28. Add player HP/Energy bars to HUD
- [x] 29. **TEST CHECKPOINT 3: PASSED**

### Phase 4: Dungeon Generation
- [x] 30. Create room.dart (room types: start, combat, vertical, treasure, exit)
- [x] 31. Create floor_generator.dart (procedural room/platform generation)
- [x] 32. Create exit_portal.dart (portal to next floor)
- [x] 33. Add floor boundaries (solid floor, walls, ceiling)
- [x] 34. Add vertical room layouts with wall-jump sections
- [x] 35. Create portal_renderer.dart (animated portal visual)
- [x] 36. Integrate floor generator with game_world
- [x] 37. Add floor transition effect
- [x] 38. **TEST CHECKPOINT 4: Procedural dungeon with multiple rooms**

### Phase 5: Currency & Economy System
**Goal**: Add a robust currency system that rewards combat and enables progression
- [x] 39. Create currency_manager.dart with gold and essence tracking
- [x] 40. Update pickup.dart to have configurable drop values
- [x] 41. Create loot_table.dart for enemy drop rates and scaling
- [x] 42. Update drifter.dart to drop gold on death (scales with floor)
- [x] 43. Add currency display to HUD (gold coin icon + count, essence star + count)
- [x] 44. Create save_system.dart with SharedPreferences for persistent currency
- [x] 45. Add floor completion gold bonus
- [x] 46. **TEST CHECKPOINT 5: Kill enemies, see gold drop, HUD updates, persists on restart**

### Phase 6: Hub/Base Room System
**Goal**: Create a safe hub area between dungeon runs where players interact with vendors
- [x] 47. Create hub_room.dart with static layout (safe zone, vendor areas, dungeon portal)
- [x] 48. Create vendor.dart base class (NPC entity with interaction zone)
- [x] 49. Create game_state.dart enum (hub, dungeon, menu) to manage game flow
- [x] 50. Update game_world.dart to handle hub vs dungeon mode
- [x] 51. Create hub_renderer.dart for vendor NPCs and decorations
- [x] 52. Add dungeon portal in hub that starts a new run
- [x] 53. Add return-to-hub on death (lose some gold, keep essence)
- [x] 54. **TEST CHECKPOINT 6: Start in hub, enter dungeon, die, return to hub**

### Phase 7: Upgrade System & Vendor Menu
**Goal**: Button-based upgrade menu accessed via vendors in the hub
- [x] 54a. Add checkpoint floors (every 3 floors, optional hub return portal)
- [x] 54b. Add dungeon progress tracking (resume from checkpoint on re-entry)
- [x] 55. Create upgrade.dart with upgrade definitions (stat boosts, abilities)
- [x] 56. Create upgrade_manager.dart to track purchased upgrades
- [x] 57. Create ui/menu_system.dart for button-based menu infrastructure
- [x] 58. Create ui/upgrade_menu.dart with upgrade grid (keyboard navigation)
- [x] 59. Create three vendor types: StatVendor, AbilityVendor, SpellVendor
- [x] 60. Add interaction prompt when near vendor ("Press E to interact")
- [x] 61. Wire vendor interaction to open corresponding upgrade menu
- [x] 62. Implement upgrade purchase flow (check currency, apply upgrade, persist)
- [x] 63. Add visual indicator for owned upgrades in menu
- [x] 64. Add Escape key to close menus
- [x] 65. Apply upgrades to player stats (HP, ATK, SPD, dash, jumps, etc.)
- [x] 66. Add combat upgrade effects (life steal, critical strikes)
- [x] 67. Persist purchased upgrades and dungeon checkpoint to save file
- [x] 68. **TEST CHECKPOINT 7: Interact with vendor, navigate menu with keyboard, buy upgrade**

### Phase 8: Magic System (COMPLETE)
**Goal**: Add mana resource and spellcasting with purchasable spells
- [x] 65. Add mana stat to player (base 100, regenerates slowly)
- [x] 66. Add mana bar to HUD (below energy bar)
- [x] 67. Create spell.dart base class (cost, cooldown, cast time, effect)
- [x] 68. Create spell_manager.dart to track equipped spells and cooldowns
- [x] 69. Create three starter spells:
  - Fireball (projectile, 20 mana, medium damage)
  - Frost Nova (AOE around player, 35 mana, slows enemies)
  - Soul Drain (short range, 15 mana, heals player for damage dealt)
- [x] 70. Create projectile.dart for spell projectiles
- [x] 71. Create spell_renderer.dart for spell visuals and projectiles
- [x] 72. Map spell casting to number keys 1-3
- [x] 73. Add spell unlock system via SpellVendor in hub
- [x] 74. **TEST CHECKPOINT 8: Cast spells, see mana drain, cooldowns work, buy new spell**

### Phase 9: Complex Dungeon Rooms
**Goal**: More varied and challenging dungeon layouts
- [ ] 75. Add TrapRoom type with spike hazards (timed or proximity)
- [ ] 76. Create spike.dart hazard entity (damages player on contact)
- [ ] 77. Add ArenaRoom type (locked until wave clear, multiple enemy waves)
- [ ] 78. Create wave_spawner.dart for timed enemy wave spawning
- [ ] 79. Add TreasureVault room (chest with bonus loot, no enemies)
- [ ] 80. Create chest.dart interactable entity (open with E key)
- [ ] 81. Add PuzzleRoom type (pressure plates + gates)
- [ ] 82. Create pressure_plate.dart and gate.dart interactables
- [ ] 83. Update floor_generator.dart to mix in new room types
- [ ] 84. Add mini-map or room indicator to HUD
- [ ] 85. **TEST CHECKPOINT 9: Encounter trap room, arena room, and treasure chest**

### Phase 10: Boss Encounters
**Goal**: Epic boss battles at milestone floors
- [ ] 86. Create boss.dart base class with phase system
- [ ] 87. Create sentinel_boss.dart (Floor 5 boss - large geometric shape)
  - Phase 1: Spinning attack patterns
  - Phase 2: Summons minions
  - Phase 3: Rage mode with faster attacks
- [ ] 88. Create boss_room.dart with large arena layout
- [ ] 89. Create boss_renderer.dart with health bar and phase indicator
- [ ] 90. Add boss music and transition effects
- [ ] 91. Update floor_generator.dart to spawn boss every 5 floors
- [ ] 92. Add boss defeat rewards (large gold + rare essence)
- [ ] 93. **TEST CHECKPOINT 10: Reach floor 5, fight boss with phases, get rewards**

### Phase 11: Polish & Balance
**Goal**: Final tuning and quality-of-life improvements
- [ ] 94. Balance economy (upgrade costs, drop rates, scaling)
- [ ] 95. Add run statistics screen on death (enemies killed, gold earned, floors cleared)
- [ ] 96. Add permanent unlocks system (new starting abilities after milestones)
- [ ] 97. Add sound effects for spells, purchases, and interactions
- [ ] 98. Add settings menu (volume, controls display)
- [ ] 99. Final playtesting and difficulty tuning
- [ ] 100. **TEST CHECKPOINT 11: Full gameplay loop feels balanced and fun**

---

## Upgrade Definitions (Phase 7)

### Stat Upgrades (StatVendor - costs Gold)
| Upgrade | Tiers | Effect per Tier | Cost per Tier |
|---------|-------|-----------------|---------------|
| Vitality | 5 | +20 max HP | 50, 100, 200, 400, 800 |
| Power | 5 | +10% attack damage | 75, 150, 300, 600, 1200 |
| Agility | 3 | +5% move speed | 100, 250, 500 |
| Endurance | 3 | +1 max dash charge | 200, 500, 1000 |
| Recovery | 3 | +20% energy regen | 150, 350, 700 |

### Ability Upgrades (AbilityVendor - costs Essence)
| Upgrade | Effect | Cost |
|---------|--------|------|
| Double Jump | Unlocks double jump | 5 essence |
| Air Dash | Can dash in mid-air | 8 essence |
| Combo Master | 4th hit in combo, +50% damage | 10 essence |
| Life Steal | 5% of damage heals player | 15 essence |
| Critical Strike | 15% chance for 2x damage | 12 essence |

### Spells (SpellVendor - costs both Gold + Essence)
| Spell | Effect | Cost |
|-------|--------|------|
| Fireball | Projectile, 40 damage, ignites | 200g + 3e |
| Frost Nova | AOE freeze, 25 damage | 300g + 5e |
| Soul Drain | Channel, drain HP | 250g + 4e |
| Lightning Bolt | Instant, chains to 2 enemies | 400g + 7e |
| Shield Barrier | Block next hit | 350g + 6e |

---

## Enemy Drop Tables (Phase 5)

| Enemy Type | Gold (base) | Essence Chance | Essence Amount |
|------------|-------------|----------------|----------------|
| Drifter (Triangle) | 5-10 | 5% | 1 |
| Drifter (Square) | 10-15 | 10% | 1 |
| Drifter (Pentagon) | 15-25 | 15% | 1-2 |
| Boss | 200-300 | 100% | 10-15 |

*Gold scales with floor: `base * (1 + floor * 0.1)`*

---

## Hub Layout (Phase 6)

```
┌─────────────────────────────────────────────────────────┐
│                      ABYSS RUNNER                       │
│                                                         │
│    ┌─────────┐          ┌───────┐          ┌─────────┐  │
│    │  STAT   │          │DUNGEON│          │  SPELL  │  │
│    │ VENDOR  │          │PORTAL │          │ VENDOR  │  │
│    └─────────┘          └───────┘          └─────────┘  │
│                                                         │
│                     ┌───────────┐                       │
│                     │  ABILITY  │                       │
│                     │  VENDOR   │                       │
│                     └───────────┘                       │
│                                                         │
│ =══════════════════════════════════════════════════════ │
│                    [PLAYER SPAWN]                       │
└─────────────────────────────────────────────────────────┘
```

---

## Room Type Distribution (Phase 9)

| Room Type | Spawn Weight | Notes |
|-----------|--------------|-------|
| Combat | 40% | Standard enemy room |
| Vertical | 20% | Platforming challenge |
| Trap | 15% | Hazard navigation |
| Arena | 10% | Wave survival |
| Treasure | 10% | Bonus loot |
| Puzzle | 5% | Pressure plate puzzle |

---

## Files Created (Phase 3)
- lib/entities/enemy.dart - Base enemy class with AI states
- lib/entities/drifter.dart - Floating geometric enemy (triangle/square/pentagon)
- lib/entities/pickup.dart - Collectible drops
- lib/combat/combat_system.dart - Hit detection and damage processing
- lib/combat/damage_numbers.dart - Floating damage text
- lib/combat/particle_system.dart - Visual particle effects
- lib/rendering/enemy_renderer.dart - Enemy drawing with health bars
- lib/rendering/effects_renderer.dart - Particles, pickups, damage numbers

## Files Created (Phase 4)
- lib/dungeon/room.dart - Room and DungeonFloor data structures
- lib/dungeon/floor_generator.dart - Procedural floor generation
- lib/dungeon/exit_portal.dart - Portal to next floor
- lib/rendering/portal_renderer.dart - Portal visual rendering
- lib/audio/audio_manager.dart - Background music playback

## Files Created (Phase 5)
- lib/economy/currency_manager.dart - Gold and essence tracking with session management
- lib/economy/loot_table.dart - Enemy drop rates and floor scaling
- lib/economy/save_system.dart - SharedPreferences persistence for currency

## Files Created (Phase 6)
- lib/game/game_state.dart - GameState enum (hub, dungeon, menu)
- lib/hub/vendor.dart - Vendor class and VendorType enum
- lib/hub/hub_room.dart - Static hub layout generator
- lib/rendering/hub_renderer.dart - Hub vendor/decoration rendering

## Controls
- **WASD / Arrow Keys**: Move
- **Space**: Jump
- **K / Shift**: Dash (8 directions, uses movement keys for direction)
- **J / Z**: Attack (3-hit combo, directional)
- **E**: Interact (enter dungeon portal, interact with vendors)

## Features Implemented (Phase 3)
- Drifter enemies that float and chase player
- Player melee attack with arc visualization
- 3-hit combo system with increasing damage
- Damage numbers (white normal, orange critical, green healing)
- Hit particles and death bursts
- Enemy health bars
- Pickups: health (+), energy (diamond), coin (circle), essence (star)
- Pickup magnet effect when near player
- Player HP and Energy bars in HUD
- Player takes damage with knockback and i-frames
- Hit flash effect on damage

## Features Implemented (Phase 4)
- Procedural floor generation with connected rooms
- Room types: start (safe), combat (enemies), vertical (platforming), exit (portal)
- Vertical room layouts with wall-jump walls
- Solid floor boundary (player can't fall off bottom)
- Exit portal that unlocks when all enemies defeated
- Floor transition effect with fade and floor number display
- Floors get larger and have more enemies on higher floors
- Enemy spawns scale with floor number
- Enemy pathfinding around platforms (steering behavior)
- 30% faster player gravity for snappier feel
- Looping background music (Chromatic Skyline)

## Features Implemented (Phase 5)
- Currency system with gold and essence
- Gold drops from all drifter enemies (scales with floor)
- Essence has chance to drop from stronger drifters (pentagon 15%, square 10%, triangle 5%)
- Loot table with configurable drop rates per enemy shape type
- Floor completion gold bonus (scales with floor number)
- HUD displays gold (coin icon) and essence (star icon) in top right
- Persistent storage using SharedPreferences (auto-saves on currency change)
- Floating damage numbers show "+Xg" for gold and "+Xe" for essence
- Health and energy drops still occur with smaller chances

## Generated Dungeon Layout
- 3-7 connected rooms depending on floor number
- Start room: safe area with platforms
- Combat rooms: platforms + drifter enemies
- Vertical rooms: tall with alternating platforms and wall-jump walls
- Exit room: elevated portal platform with guardian enemies

## Features Implemented (Phase 6)
- Hub/base room as the game's starting area (800x600 safe zone)
- Three vendor NPCs rendered as colored hexagons (stat=gold, ability=purple, spell=blue)
- Vendors show name labels and "Press E" prompt when player is nearby
- Dungeon portal in hub center (always unlocked, press E to enter)
- Game state system (hub vs dungeon) controlling flow and rendering
- "Entering the Abyss..." transition when starting a dungeon run
- Death detection with "YOU DIED" overlay and gold loss display
- Return-to-hub on death (lose 50% session gold, keep all essence)
- "Returning to Hub..." transition after death
- Hub-specific background (dark purple-blue), cyan platform glow, "ABYSS RUNNER" title
- Context-sensitive HUD (shows "HUB" vs "Floor: N", hides enemy count in hub)
- Context-sensitive controls hint (shows E: Interact in hub)
- E key added to input system for interactions

## Features Implemented (Phase 7)
- **Checkpoint portals every 3 floors** (floors 3, 6, 9...): Optional hub return portal alongside normal exit portal
- **Dungeon progress tracking**: Checkpoint floor saved, next dungeon entry resumes from last checkpoint (e.g., floor 4 after clearing floor 3)
- **Voluntary hub return**: Via checkpoint portal, awards floor completion bonus, saves progress, NO gold loss
- **Death behavior**: Return to hub with 50% gold loss, but keep checkpoint progress
- **Upgrade system**: 5 stat upgrades (Vitality, Power, Agility, Endurance, Recovery) with 3-5 tiers each
- **Ability unlocks**: 5 abilities (Double Jump, Air Dash, Combo Master, Life Steal, Critical Strike) purchased with essence
- **Spell placeholders**: 3 spell slots marked "Coming Soon" (Phase 8 implementation)
- **Vendor interaction**: Press E near vendors in hub to open category-specific upgrade menu
- **Upgrade menu**: Keyboard-navigated (W/S for selection, E/J to purchase, Esc to close)
- **Visual feedback**: Selected row highlighted, tier pips showing progress, cost/affordability indicators, MAX/LOCKED status
- **Stat application**: Upgrades apply to player stats (HP, attack multiplier, move speed, dash cooldown, energy regen)
- **Combat effects**: Life steal heals on hit, critical strikes roll for 2x damage with visual feedback (orange sparks)
- **Movement upgrades**: Double jump and air dash functional, combo master enables 4th hit
- **Persistence**: Purchased upgrades and checkpoint floor saved to SharedPreferences, load on startup
- **HUD updates**: Floor display shows "(checkpoint!)" on checkpoint floors, hub portal shows resume floor
- **Portal visuals**: Hub return portal rendered in cyan color, distinct from green exit portal

## Features Implemented (Phase 8)
- **Mana system**: Player has 100 max mana, regenerates 3 mana per second
- **Mana HUD**: Purple mana bar displayed below energy bar in HUD
- **Spell infrastructure**: Spell base class with cost, cooldown, cast time, and effect execution
- **Projectile system**: Spell projectiles with collision detection, lifetime, and visual trails
- **Spell manager**: Tracks equipped spells (3 slots), unlocked spells, and active projectiles
- **Three spells implemented**:
  - Fireball: Fast projectile, 40 damage, 20 mana, 1.5s cooldown
  - Frost Nova: AOE freeze, 25 damage, slows enemies 50% for 2s, 35 mana, 4s cooldown
  - Soul Drain: Drains nearby enemy HP, heals player 75% of damage, 15 mana, 2s cooldown
- **Spell rendering**: Projectile visuals with glow effects, spell HUD with cooldown indicators
- **Spell casting**: Number keys 1-3 cast equipped spells (dungeon only)
- **Spell vendor**: Purchase spells with gold + essence, auto-equip to first empty slot
- **Enemy slow effect**: Frost Nova applies slow debuff, reduces movement speed
- **Spell persistence**: Unlocked spells saved to SharedPreferences, auto-equipped on load
- **Spell-enemy interactions**: Projectiles deal damage, spawn loot on kill, show damage numbers

## Files Created (Phase 8)
- lib/spells/spell.dart - Base spell class with cost, cooldown, casting
- lib/spells/projectile.dart - Spell projectile entity with collision
- lib/spells/spell_manager.dart - Manages equipped spells, unlocks, projectiles
- lib/spells/fireball_spell.dart - Fireball spell implementation
- lib/spells/frost_nova_spell.dart - Frost Nova AOE spell
- lib/spells/soul_drain_spell.dart - Soul Drain life-steal spell
- lib/rendering/spell_renderer.dart - Renders projectiles and spell HUD

## Rabbit Holes / Issues to Resolve
(None yet)

## Notes
- Started: 2026-02-05
- Using raw Flutter with CustomPainter + Ticker (NO Flame engine)
- Desktop/keyboard controls first, touch controls later
