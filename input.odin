package main

import "core:os"
import rl "vendor:raylib"

handle_input_main_menu :: proc(game_state: ^GameState, character_state: ^CharacterState) {
	using rl.KeyboardKey
	idx := game_state.menu_index

	if rl.IsKeyPressed(.DOWN) || rl.IsKeyPressed(.S) do if idx < 3 do idx += 1
	if rl.IsKeyPressed(.UP) || rl.IsKeyPressed(.W) do if idx > 0 do idx -= 1
	if rl.IsKeyPressed(.KP_ENTER) || rl.IsKeyPressed(.ENTER) || rl.IsKeyPressed(.SPACE) {
		switch idx {
		case 0:
			reset_game(game_state, character_state)
			game_state.mode = GameMode.PlayGame
		case 1:
			game_state.mode = GameMode.TileEditor
		case 2:
			change_difficulty(game_state)
		case 3:
			os.exit(0)
		}
	}

	game_state.menu_index = idx
}

handle_input :: proc(
	game_state: ^GameState,
	character_state: ^CharacterState,
	camera: ^rl.Camera2D,
) {
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
				// Restart game
				reset_game(game_state, character_state)
				game_state.is_paused = false
			case 2:
				// To the main menu
				game_state.menu_index = 0
				game_state.mode = GameMode.MainMenu
			}
		}

		if idx >= 0 && idx <= 2 do game_state.menu_index = idx
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
		game_state.mode = GameMode.TileEditor
	}

	if character_on_the_move do move_character(character_state, game_state)

	// Map scrolling
	if rl.IsKeyDown(.W) {
		camera.target.y -= 10
	} else if rl.IsKeyDown(.S) {
		camera.target.y += 10
	} else if rl.IsKeyDown(.A) {
		camera.target.x -= 10
	} else if rl.IsKeyDown(.D) {
		camera.target.x += 10
	}

	// Zoom control
	if rl.IsKeyDown(.Q) {
		camera.zoom += 0.02
	} else if rl.IsKeyDown(.E) {
		camera.zoom -= 0.02
	}

	// Pause the game
	if rl.IsKeyPressed(.ESCAPE) {
		game_state.menu_index = 0
		game_state.is_paused = true
	}
}

handle_input_tile_editor :: proc(game_state: ^GameState, camera: ^rl.Camera2D) {
	using rl.KeyboardKey

	// Go back to main menu
	if rl.IsKeyPressed(.ESCAPE) {
		write_map(game_state, "assets/map.txt")
		game_state.mode = GameMode.MainMenu
	}

	// Map scrolling
	if rl.IsKeyDown(.W) do camera.target.y -= 10
	else if rl.IsKeyDown(.S) do camera.target.y += 10
	else if rl.IsKeyDown(.A) do camera.target.x -= 10
	else if rl.IsKeyDown(.D) do camera.target.x += 10

	// Zoom control
	if rl.IsKeyDown(.Q) do camera.zoom += 0.02
	else if rl.IsKeyDown(.E) do camera.zoom -= 0.02

	// Change tile edit position
	xPos, yPos := game_state.tile_edit_position.x, game_state.tile_edit_position.y
	if rl.IsKeyPressed(.UP) && yPos > 0 do game_state.tile_edit_position.y -= 1
	else if rl.IsKeyPressed(.DOWN) && yPos < GRID_HEIGHT - 1 do game_state.tile_edit_position.y += 1
	else if rl.IsKeyPressed(.LEFT) && xPos > 0 do game_state.tile_edit_position.x -= 1
	else if rl.IsKeyPressed(.RIGHT) && xPos < GRID_WIDTH - 1 do game_state.tile_edit_position.x += 1

	// Change tile
	if rl.IsKeyPressed(.SPACE) do update_tile_and_neighbors(game_state, game_state.tile_edit_position)
}
