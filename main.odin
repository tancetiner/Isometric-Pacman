package main

import rl "vendor:raylib"

main :: proc() {
	rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "Isometric Pacman")
	rl.SetTargetFPS(FPS)
	defer rl.CloseWindow()

	// Initialize Textures
	textureMap: map[string]rl.Texture2D = loadTextures()

	defer {
		for _, value in textureMap {
			rl.UnloadTexture(value)
		}
	}

	// Initialize Game State
	gameMap, gameMapBoolean := read_map("./assets/map.txt")

	// Initialize Enemies
	enemies: [4]CharacterState = initializeEnemies()

	game_state: GameState = GameState {
		game_mode          = GameMode.Normal,
		game_map           = gameMap,
		game_map_boolean   = gameMapBoolean,
		tile_edit_position = {0, 0},
		enemies            = enemies,
	}

	// Initialize Character State
	character_state: CharacterState = CharacterState {
		pose                  = 0,
		pose_time_counter     = 0.0,
		movement_time_counter = 0.0,
		action                = CharacterAction.Standing,
		position              = {11, 1},
		direction             = Direction.Down,
	}

	// Randomly place character and enemies
	placeCharacters(&game_state, &character_state)

	// Initialize Camera
	// xPos, yPos := characterTilePositionToScreenPosition(character_state.position)
	camera := rl.Camera2D {
		// rl.Vector2{WINDOW_WIDTH / 2, WINDOW_HEIGHT / 2},
		// rl.Vector2{xPos, yPos},
		rl.Vector2{WINDOW_WIDTH / 2, 0.0},
		rl.Vector2{0.0, 0.0},
		0.0,
		0.8,
	}

	// Main game loop
	for !rl.WindowShouldClose() {
		rl.BeginDrawing()
		rl.ClearBackground(rl.RAYWHITE)
		rl.BeginMode2D(camera)

		switch game_state.game_mode {
		case GameMode.Normal:
			// Update character state
			updateCharacterAndEnemiesState(&game_state, &character_state)

			// Handling Input
			handleInput(&game_state, &character_state, &camera)

			// Update Camera
			// updateCamera(&character_state, &camera)

			// Draw Game
			drawNormalMode(&game_state, &character_state, &textureMap)

		case GameMode.TileEditor:
			// Handling Input
			handleInputForTileEditor(&game_state, &camera)

			// Draw Tile Editor
			drawTileEditorMode(&game_state, &character_state, &textureMap)
		}

		// End Drawing
		rl.EndMode2D()
		rl.EndDrawing()
	}
}
