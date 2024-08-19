package main

import rl "vendor:raylib"

main :: proc() {
	rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "Isometric Pacman")
	rl.SetTargetFPS(FPS)
	defer rl.CloseWindow()

	// Initialize Textures
	textureMap: map[string]rl.Texture2D = load_textures()

	defer {
		for _, value in textureMap {
			rl.UnloadTexture(value)
		}
	}

	// Initialize Game State
	gameMap, gameMapBoolean := read_map("./assets/map.txt")

	game_state: GameState = GameState {
		mode                 = GameMode.MainMenu,
		game_map             = gameMap,
		game_map_boolean     = gameMapBoolean,
		tile_edit_position   = {0, 0},
		enemies              = {},
		menu_index           = 0,
		counter              = 0.0,
		difficulty           = GameDifficulty.Easy,
		score                = 0,
		score_coefficient    = 1,
		total_duration       = 0.0,
		collected_count      = 0,
		collectible_position = {},
		high_scores          = read_high_scores(),
		last_mode            = GameMode.MainMenu,
	}

	// Initialize Enemies
	initialize_enemies(&game_state)

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
	place_characters(&game_state, &character_state)

	// Randomly place collectible
	place_collectible(&game_state, &character_state)

	// Initialize Camera
	camera := rl.Camera2D{rl.Vector2{WINDOW_WIDTH / 2, 0.0}, rl.Vector2{0.0, 0.0}, 0.0, 1.0}

	// Main game loop
	for true {
		rl.BeginDrawing()
		rl.ClearBackground(rl.RAYWHITE)

		switch game_state.mode {
		case GameMode.MainMenu:
			// Handling Input
			handle_input_main_menu(&game_state, &character_state)

			// Draw Main Menu
			draw_main_menu(&game_state)

		case GameMode.PlayGame:
			rl.BeginMode2D(camera)

			// Update game and character state
			update_state(&game_state, &character_state)

			// Handling Input
			handle_input_play_game(&game_state, &character_state, &camera)

			// Draw Game
			draw_normal_mode(&game_state, &character_state, &textureMap)

			rl.EndMode2D()

		case GameMode.EditMap:
			rl.BeginMode2D(camera)

			// Handling Input
			handle_input_edit_map(&game_state, &camera)

			// Draw Edit Map Mode
			draw_edit_map_mode(&game_state, &textureMap)

			rl.EndMode2D()

		case GameMode.ShowHelp:
			// Handling Input for Help
			handle_input_show_help(&game_state)

			// Draw Help Screen
			draw_show_help_mode(&game_state)

		case GameMode.GameOver:
			// Update counter
			game_state.counter += rl.GetFrameTime()

			// Counter to go back to main menu
			if game_state.counter > 3.0 {
				check_high_score(&game_state)
				game_state.mode = GameMode.MainMenu
			}

			// Draw Game Over
			draw_game_over(&game_state)
		}

		// End Drawing
		rl.EndDrawing()
	}
}
