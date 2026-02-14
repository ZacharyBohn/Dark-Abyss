import 'package:flutter/painting.dart';

// =============================================================================
// PLAYER CONSTANTS
// =============================================================================
const double playerSpeed = 300.0; // pixels/sec
const double jumpForce = -500.0; // negative = up
const double gravity = 1560.0; // pixels/sec² (30% faster fall)
const double dashSpeed = 1050.0; // pixels/sec (70% of original)
const double dashDuration = 0.12; // seconds
const double dashCooldown = 0.3; // seconds
const double attackDuration = 0.15; // seconds
const double attackRange = 60.0; // pixels
const double attackArc = 120.0; // degrees

const double playerWidth = 30.0;
const double playerHeight = 40.0;

// Player base stats
const double playerBaseHP = 100.0;
const double playerBaseATK = 10.0;
const double playerBaseDEF = 5.0;
const double playerBaseSPD = 1.0;
const double playerBaseEnergy = 50.0;

// Player stat growth per level
const double hpPerLevel = 15.0;
const double atkPerLevel = 3.0;
const double defPerLevel = 2.0;
const double spdPerLevel = 0.02;
const double dashCdReductionPerLevel = 0.005;
const double energyPerLevel = 5.0;

// =============================================================================
// CAMERA CONSTANTS
// =============================================================================
const double cameraSmoothing = 0.1;
const double cameraLookAhead = 50.0;
const double screenShakeDecay = 0.9;

// =============================================================================
// DUNGEON CONSTANTS
// =============================================================================
const double tileSize = 40.0;
const int minPlatformWidth = 3; // tiles
const int maxPlatformWidth = 8; // tiles
const double minGapWidth = 80.0; // pixels (must be jumpable)
const double maxGapWidth = 200.0; // pixels (must be dashable)
const double baseFloorWidth = 800.0; // pixels
const double floorWidthPerLevel = 100.0; // additional pixels per floor

// =============================================================================
// ENEMY CONSTANTS
// =============================================================================
const double enemyDetectRange = 300.0; // pixels
const double enemyHitStunDuration = 0.2; // seconds
const double floorScaling = 0.15; // 15% stronger per floor

// =============================================================================
// PROGRESSION CONSTANTS
// =============================================================================
const double xpBase = 50.0;
const double xpExponent = 1.5;
const int checkpointFloorInterval = 3; // Return-to-hub portal every N floors

// =============================================================================
// VISUAL CONSTANTS
// =============================================================================
const double glowRadius = 8.0;
const double afterimageOpacityDecay = 0.7;
const int maxAfterimages = 4;
const int maxParticles = 200;

// =============================================================================
// COLORS
// =============================================================================
const Color playerColor = Color(0xFF00FFFF); // Cyan
const Color playerGlowColor = Color(0x8000FFFF);
const Color backgroundColor = Color(0xFF0A0A12);
const Color platformColor = Color(0xFF1A1A2E);
const Color platformGlowColor = Color(0xFF2A2A4E);

Color getFloorPrimaryColor(int floor) {
  final hue = (floor * 25.0) % 360;
  return HSLColor.fromAHSL(1.0, hue, 0.8, 0.5).toColor();
}

Color getFloorBackgroundColor(int floor) {
  final hue = (floor * 25.0) % 360;
  return HSLColor.fromAHSL(1.0, hue, 0.3, 0.08).toColor();
}

Color getFloorAccentColor(int floor) {
  final hue = ((floor * 25.0) + 180) % 360; // Complementary
  return HSLColor.fromAHSL(1.0, hue, 0.7, 0.6).toColor();
}
