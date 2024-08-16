package main

import "core:math"
import "core:math/rand"
import "core:strings"
import rl "vendor:raylib"

tile_position_to_screen_position :: proc(
	position: TilePosition,
	texture_type := TextureType.Tile,
) -> ScreenPosition {
	x := f32(position.x - position.y) * (TEXTURE_WIDTH / 2)
	y := f32(position.x + position.y) * (TEXTURE_HEIGHT / 4)

	#partial switch texture_type {
	case TextureType.Character:
		y -= TEXTURE_HEIGHT / 2 + TEXTURE_HEIGHT / 8
	case TextureType.Enemy:
		y -= TEXTURE_HEIGHT / 4
	}

	return {x, y}
}


update_state :: proc(game_state: ^GameState, character_state: ^CharacterState) {
	if game_state.is_paused do return

	delta_time := rl.GetFrameTime()
	game_state.score_coefficient = int(math.floor(game_state.total_duration / 15.0)) + 1

	// Check collision between character and enemies
	if check_collision_between_character_and_enemies(game_state, character_state) do game_state.mode = GameMode.GameOver

	// Check collision between character and collectible
	if check_collision_between_character_and_collectible(game_state, character_state) {
		game_state.collected_count += 1
		game_state.score += 10 * game_state.score_coefficient
		place_collectible(game_state, character_state)
	}


	// Update game GameState
	game_state.counter += delta_time
	game_state.total_duration += delta_time

	// Update character state
	character_state.movement_time_counter += delta_time
	character_state.pose_time_counter += delta_time

	if character_state.pose_time_counter > CHARACTER_POSE_INTERVAL {
		character_state.pose_time_counter = 0.0
		character_state.pose += 1
	}

	// Update enemies state
	for i in 0 ..< gameDifficultyToNumberOfEnemies[game_state.difficulty] {
		enemy_state := &game_state.enemies[i]
		enemy_state.movement_time_counter += delta_time
		enemy_state.pose_time_counter += delta_time

		if enemy_state.pose_time_counter > ENEMY_POSE_INTERVAL {
			enemy_state.pose_time_counter = 0.0
			enemy_state.pose += 1
		}

		handle_enemy_movement(game_state, enemy_state)
	}
}

is_possible_to_go_direction :: proc(
	game_state: ^GameState,
	position: TilePosition,
	direction: Direction,
) -> bool {
	x, y := position.x, position.y

	#partial switch direction {
	case Direction.Up:
		{
			if y > 0 && game_state.game_map_boolean[y - 1][x] do return true
		}
	case Direction.Down:
		{
			if y < GRID_HEIGHT - 1 && game_state.game_map_boolean[y + 1][x] do return true
		}
	case Direction.Left:
		{
			if x > 0 && game_state.game_map_boolean[y][x - 1] do return true
		}
	case Direction.Right:
		{
			if x < GRID_WIDTH - 1 && game_state.game_map_boolean[y][x + 1] do return true
		}
	}

	return false
}

f32_to_cstring :: proc(f: f32) -> cstring {
	builder := strings.builder_make()
	strings.write_f32(&builder, f, 'f')
	return strings.to_cstring(&builder)
}

f32_to_string :: proc(f: f32) -> string {
	builder := strings.builder_make()
	strings.write_f32(&builder, f, 'f')
	return strings.to_string(builder)
}

int_to_string :: proc(i: int) -> string {
	builder := strings.builder_make()
	strings.write_int(&builder, i)
	return strings.to_string(builder)
}

update_tile_and_neighbors :: proc(game_state: ^GameState, position: TilePosition) {
	x, y := position.x, position.y
	if game_state.game_map_boolean[y][x] {
		game_state.game_map[y][x] = 'O'
		game_state.game_map_boolean[y][x] = false
		return
	}

	// Call update_tile for self
	update_tile(game_state, {x, y})

	// Call update_tile for all neighbors
	if x > 0 && game_state.game_map_boolean[y][x - 1] do update_tile(game_state, {position.x - 1, position.y}) // Left
	if y > 0 && game_state.game_map_boolean[y - 1][x] do update_tile(game_state, {position.x, position.y - 1}) // Top
	if x < GRID_WIDTH - 1 && game_state.game_map_boolean[y][x + 1] do update_tile(game_state, {position.x + 1, position.y}) // Right
	if y < GRID_HEIGHT - 1 && game_state.game_map_boolean[y + 1][x] do update_tile(game_state, {position.x, position.y + 1}) // Down
}

update_tile :: proc(game_state: ^GameState, position: TilePosition) {
	x, y := position.x, position.y

	isNeighborOccupied: [4]bool

	// Left
	if x > 0 && game_state.game_map_boolean[y][x - 1] do isNeighborOccupied[0] = true
	// Top
	if y > 0 && game_state.game_map_boolean[y - 1][x] do isNeighborOccupied[1] = true
	// Right
	if x < GRID_WIDTH - 1 && game_state.game_map_boolean[y][x + 1] do isNeighborOccupied[2] = true
	// Down
	if y < GRID_HEIGHT - 1 && game_state.game_map_boolean[y + 1][x] do isNeighborOccupied[3] = true

	switch isNeighborOccupied {
	case {false, false, false, false}:
		game_state.game_map[y][x] = 'X'
	case {true, false, false, false}:
		game_state.game_map[y][x] = '-'
	case {false, true, false, false}:
		game_state.game_map[y][x] = '|'
	case {false, false, true, false}:
		game_state.game_map[y][x] = '-'
	case {false, false, false, true}:
		game_state.game_map[y][x] = '|'
	case {true, true, false, false}:
		game_state.game_map[y][x] = ']'
	case {true, false, true, false}:
		game_state.game_map[y][x] = '-'
	case {true, false, false, true}:
		game_state.game_map[y][x] = '}'
	case {false, true, true, false}:
		game_state.game_map[y][x] = '['
	case {false, true, false, true}:
		game_state.game_map[y][x] = '|'
	case {false, false, true, true}:
		game_state.game_map[y][x] = '{'
	case {true, true, true, false}:
		game_state.game_map[y][x] = 'Z'
	case {true, true, false, true}:
		game_state.game_map[y][x] = 'J'
	case {true, false, true, true}:
		game_state.game_map[y][x] = 'T'
	case {false, true, true, true}:
		game_state.game_map[y][x] = 'L'
	case {true, true, true, true}:
		game_state.game_map[y][x] = 'X'
	}

	game_state.game_map_boolean[y][x] = true
}

update_camera :: proc(character_state: ^CharacterState, camera: ^rl.Camera2D) {
	position := tile_position_to_screen_position(character_state.position, TextureType.Character)
	camera.target = rl.Vector2{f32(position.x), f32(position.y)}
}

initialize_enemies :: proc(game_state: ^GameState) {
	for i in 0 ..< gameDifficultyToNumberOfEnemies[game_state.difficulty] {
		append(
			&game_state.enemies,
			CharacterState {
				pose = 0,
				pose_time_counter = 0.0,
				movement_time_counter = 0.0,
				action = CharacterAction.Walking,
				position = {i + 1, i + 1},
				direction = Direction.Down,
			},
		)
	}
}

place_characters :: proc(game_state: ^GameState, character_state: ^CharacterState) {
	available_positions: [dynamic]TilePosition
	defer delete(available_positions)

	for row in 0 ..< GRID_HEIGHT {
		for col in 0 ..< GRID_WIDTH {
			if game_state.game_map_boolean[row][col] {
				append(&available_positions, TilePosition{col, row})
			}
		}
	}

	// Place character
	idx := rand.int31() % i32(len(available_positions))
	character_state.position = available_positions[idx]
	unordered_remove(&available_positions, int(idx))

	// Place enemies
	for i in 0 ..< gameDifficultyToNumberOfEnemies[game_state.difficulty] {
		idx := rand.int31() % i32(len(available_positions))
		for math.abs(
			    available_positions[idx].x -
			    character_state.position.x +
			    math.abs(available_positions[idx].y - character_state.position.y),
		    ) <
		    6 {
			idx = rand.int31() % i32(len(available_positions))
		}
		game_state.enemies[i].position = available_positions[idx]
		unordered_remove(&available_positions, int(idx))
	}
}

check_collision_between_character_and_enemies :: proc(
	game_state: ^GameState,
	character_state: ^CharacterState,
) -> bool {
	x, y := character_state.position.x, character_state.position.y

	for i in 0 ..< gameDifficultyToNumberOfEnemies[game_state.difficulty] {
		enemy_state := game_state.enemies[i]
		if enemy_state.position.x == x && enemy_state.position.y == y do return true
	}

	return false
}

change_difficulty :: proc(game_state: ^GameState) {
	using GameDifficulty

	switch game_state.difficulty {
	case .Easy:
		game_state.difficulty = .Medium
	case .Medium:
		game_state.difficulty = .Hard
	case .Hard:
		game_state.difficulty = .Easy
	}
}

reset_game :: proc(game_state: ^GameState, character_state: ^CharacterState) {
	game_state.score = 0
	game_state.menu_index = 0
	game_state.counter = 0.0
	game_state.total_duration = 0.0
	game_state.collected_count = 0
	game_state.is_paused = false
	game_state.collectible_position = {}
	clear(&game_state.enemies)
	initialize_enemies(game_state)
	place_characters(game_state, character_state)
	place_collectible(game_state, character_state)
}

check_collision_between_character_and_collectible :: proc(
	game_state: ^GameState,
	character_state: ^CharacterState,
) -> bool {
	if character_state.position.x == game_state.collectible_position.x &&
	   character_state.position.y == game_state.collectible_position.y {
		return true
	}

	return false
}

place_collectible :: proc(game_state: ^GameState, character_state: ^CharacterState) {
	availablePositions: [dynamic]TilePosition
	defer delete(availablePositions)
	characterPosition := character_state.position

	for row in 0 ..< GRID_HEIGHT {
		for col in 0 ..< GRID_WIDTH {
			if game_state.game_map_boolean[row][col] &&
			   (math.abs(col - characterPosition.x) + math.abs(row - characterPosition.y)) > 5 {
				append(&availablePositions, TilePosition{col, row})
			}
		}
	}

	// Place collectible
	idx := rand.int31() % i32(len(availablePositions))
	game_state.collectible_position = availablePositions[idx]
}

check_high_score :: proc(game_state: ^GameState) {
	if game_state.score > game_state.high_scores[game_state.difficulty] {
		game_state.high_scores[game_state.difficulty] = game_state.score
		write_high_scores(game_state.high_scores)
	}
}
