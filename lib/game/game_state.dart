/// Top-level game state controlling which mode the game is in
enum GameState {
  startScreen, // Initial start screen before game begins
  hub, // Safe hub area with vendors
  dungeon, // Active dungeon run
  menu, // Menu overlay (for future use)
}
