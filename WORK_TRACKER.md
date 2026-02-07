# Abyss Runner - Work Tracker

## Current Phase: Phase 4 - Dungeon Generation
## Current Status: READY FOR TEST CHECKPOINT 4

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

### Phase 5-9: (Future phases listed in design doc)

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

## Controls
- **WASD / Arrow Keys**: Move
- **Space**: Jump
- **K / Shift**: Dash (8 directions, uses movement keys for direction)
- **J / Z**: Attack (3-hit combo, directional)

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

## Generated Dungeon Layout
- 3-7 connected rooms depending on floor number
- Start room: safe area with platforms
- Combat rooms: platforms + drifter enemies
- Vertical rooms: tall with alternating platforms and wall-jump walls
- Exit room: elevated portal platform with guardian enemies

## Rabbit Holes / Issues to Resolve
(None yet)

## Notes
- Started: 2026-02-05
- Using raw Flutter with CustomPainter + Ticker (NO Flame engine)
- Desktop/keyboard controls first, touch controls later
