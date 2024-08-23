package main

import "core:os"
import rl "vendor:raylib"

handle_input_main_menu :: proc(game_state: ^GameState, character_state: ^CharacterState) {
	using rl.KeyboardKey
	idx := game_state.menu_index

	if rl.IsKeyPressed(.DOWN) || rl.IsKeyPressed(.S) do if idx < 4 do idx += 1
	if rl.IsKeyPressed(.UP) || rl.IsKeyPressed(.W) do if idx > 0 do idx -= 1
	if rl.IsKeyPressed(.KP_ENTER) || rl.IsKeyPressed(.ENTER) || rl.IsKeyPressed(.SPACE) {
		switch idx {
		case 0:
			reset_game(game_state, character_state)
			game_state.mode = GameMode.PlayGame
		case 1:
			game_state.tile_edit_position = {GRID_WIDTH / 2, GRID_HEIGHT / 2}
			game_state.mode = GameMode.EditMap
		case 2:
			change_difficulty(game_state)
		case 3:
			game_state.last_mode = GameMode.MainMenu
			game_state.mode = GameMode.ShowHelp
		case 4:
			os.exit(0)
		}
	}

	game_state.menu_index = idx
}

handle_input_play_game :: proc(game_state: ^GameState, character_state: ^CharacterState) {
	using rl.KeyboardKey

	// Pause menu logic
	if game_state.is_paused {
		idx := game_state.menu_index
		if rl.IsKeyPressed(.DOWN) || rl.IsKeyPressed(.S) && idx < 3 do idx += 1
		if rl.IsKeyPressed(.UP) || rl.IsKeyPressed(.W) && idx > 0 do idx -= 1
		if rl.IsKeyPressed(.KP_ENTER) || rl.IsKeyPressed(.ENTER) || rl.IsKeyPressed(.SPACE) {
			switch idx {
			case 0:
				// Resume game
				game_state.is_paused = false
			case 1:
				// Restart game
				reset_game(game_state, character_state)
				game_state.is_paused = false
			case 2:
				// Show help
				game_state.last_mode = GameMode.PlayGame
				game_state.mode = GameMode.ShowHelp
			case 3:
				// To the main menu
				game_state.menu_index = 0
				game_state.is_paused = false
				game_state.mode = GameMode.MainMenu
			}
		}

		if idx >= 0 && idx <= 3 do game_state.menu_index = idx
		return
	}

	// Character Movement
	isTimeToMove := character_state.movement_time_counter > CHARACTER_MOVEMENT_INTERVAL
	if isTimeToMove do character_state.movement_time_counter = 0
	character_state.action = CharacterAction.Standing
	character_on_the_move := false


	if (rl.IsKeyDown(.RIGHT) || rl.IsKeyDown(.DOWN) || rl.IsKeyDown(.UP) || rl.IsKeyDown(.LEFT)) do character_state.action = CharacterAction.Walking

	direction := Direction.None
	if rl.IsKeyDown(.RIGHT) {
		direction = Direction.Right
	} else if rl.IsKeyDown(.LEFT) {
		direction = Direction.Left
	} else if rl.IsKeyDown(.UP) {
		direction = Direction.Up
	} else if rl.IsKeyDown(.DOWN) {
		direction = Direction.Down
	}

	if direction != Direction.None {
		if character_state.direction != direction || isTimeToMove {
			if character_state.direction != direction do character_state.movement_time_counter = 0.0
			character_state.movement_time_counter = 0.0
			character_state.direction = direction
			character_on_the_move = true
		}
	} else if rl.IsKeyPressed(.M) {
		game_state.mode = GameMode.EditMap
	}

	if character_on_the_move do move_character(character_state, game_state)

	// Pause the game
	if rl.IsKeyPressed(.ESCAPE) {
		game_state.menu_index = 0
		game_state.is_paused = true
	}
}

handle_input_edit_map :: proc(game_state: ^GameState) {
	using rl.KeyboardKey

	// Pause menu logic
	if game_state.is_paused {
		idx := game_state.menu_index
		if rl.IsKeyPressed(.DOWN) || rl.IsKeyPressed(.S) && idx < 2 do idx += 1
		if rl.IsKeyPressed(.UP) || rl.IsKeyPressed(.W) && idx > 0 do idx -= 1
		if rl.IsKeyPressed(.KP_ENTER) || rl.IsKeyPressed(.ENTER) || rl.IsKeyPressed(.SPACE) {
			switch idx {
			case 0:
				// Resume game
				game_state.is_paused = false
			case 1:
				// Save and exit
				write_map(game_state, "assets/map.txt")
				game_state.is_paused = false
				game_state.menu_index = 0
				game_state.mode = GameMode.MainMenu
			case 2:
				// Discard and exit
				read_map(game_state, "assets/map.txt")
				game_state.is_paused = false
				game_state.menu_index = 0
				game_state.mode = GameMode.MainMenu
			}
		}

		if idx >= 0 && idx <= 2 do game_state.menu_index = idx
		return
	}

	// Pause the edit map mode
	if rl.IsKeyPressed(.ESCAPE) {
		game_state.menu_index = 0
		game_state.is_paused = true
	}

	// Change tile edit position
	xPos, yPos := game_state.tile_edit_position.x, game_state.tile_edit_position.y
	if rl.IsKeyPressed(.UP) && yPos > 0 && game_state.isOnScreen[yPos - 1][xPos] do game_state.tile_edit_position.y -= 1
	else if rl.IsKeyPressed(.DOWN) && yPos < GRID_HEIGHT - 1 && game_state.isOnScreen[yPos + 1][xPos] do game_state.tile_edit_position.y += 1
	else if rl.IsKeyPressed(.LEFT) && xPos > 0 && game_state.isOnScreen[yPos][xPos - 1] do game_state.tile_edit_position.x -= 1
	else if rl.IsKeyPressed(.RIGHT) && xPos < GRID_WIDTH - 1 && game_state.isOnScreen[yPos][xPos + 1] do game_state.tile_edit_position.x += 1

	// Change tile
	if rl.IsKeyPressed(.SPACE) do update_tile_and_neighbors(game_state, game_state.tile_edit_position)
}

handle_input_show_help :: proc(game_state: ^GameState) {
	using rl.KeyboardKey

	if rl.IsKeyPressed(.ESCAPE) || rl.IsKeyPressed(.ENTER) || rl.IsKeyPressed(.SPACE) || rl.IsKeyPressed(.KP_ENTER) do game_state.mode = game_state.last_mode
}
