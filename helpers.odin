package main

import "core:fmt"
import "core:math"
import "core:math/rand"
import "core:os"
import "core:strings"
import "core:unicode/utf8"
import rl "vendor:raylib"

read_map :: proc(
	filepath: string,
) -> (
	[GRID_HEIGHT][GRID_WIDTH]rune,
	[GRID_HEIGHT][GRID_WIDTH]bool,
) {
	data, ok := os.read_entire_file(filepath, context.allocator)
	if !ok {
		// could not read file
		fmt.println("Could not read file")
		return [GRID_HEIGHT][GRID_WIDTH]rune{}, [GRID_HEIGHT][GRID_WIDTH]bool{}
	}
	defer delete(data)

	gameMap: [GRID_HEIGHT][GRID_WIDTH]rune
	gameMapBoolean: [GRID_HEIGHT][GRID_WIDTH]bool

	it := string(data)
	idx := 0
	for line in strings.split_lines_iterator(&it) {
		for col in 0 ..< GRID_WIDTH {
			if col < len(line) {
				gameMap[idx][col] = rune(line[col]) // Convert char to rune
				if line[col] == 'O' do gameMapBoolean[idx][col] = false
				else do gameMapBoolean[idx][col] = true
			} else {
				gameMap[idx][col] = 'O' // Fill with O if line is shorter
			}
		}
		idx += 1
	}

	return gameMap, gameMapBoolean
}


write_map :: proc(game_state: ^GameState, filepath: string) {
	game_map_string: string
	for row in 0 ..< GRID_HEIGHT {
		rune_array: [dynamic]rune
		for col in 0 ..< GRID_WIDTH {
			append(&rune_array, game_state.game_map[row][col])
		}
		game_map_string = strings.concatenate(
			{game_map_string, utf8.runes_to_string(rune_array[:]), "\n"},
		)
	}
	data: []u8 = transmute([]u8)game_map_string

	if os.write_entire_file(filepath, data) do fmt.println("File written successfully")
	else do fmt.println("Could not write file")
}


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

move_character :: proc(character_state: ^CharacterState, game_state: ^GameState) {
	newCharacterPosition := character_state.position

	#partial switch character_state.direction {
	case Direction.Up:
		{
			if character_state.position.y > 0 &&
			   game_state.game_map[character_state.position.y - 1][character_state.position.x] !=
				   'O' {
				newCharacterPosition.y -= 1
			}
		}

	case Direction.Down:
		{
			if character_state.position.y < GRID_HEIGHT - 1 &&
			   game_state.game_map[character_state.position.y + 1][character_state.position.x] !=
				   'O' {
				newCharacterPosition.y += 1
			}
		}

	case Direction.Left:
		{
			if character_state.position.x > 0 &&
			   game_state.game_map[character_state.position.y][character_state.position.x - 1] !=
				   'O' {
				newCharacterPosition.x -= 1
			}
		}

	case Direction.Right:
		{
			if character_state.position.x < GRID_WIDTH - 1 &&
			   game_state.game_map[character_state.position.y][character_state.position.x + 1] !=
				   'O' {
				newCharacterPosition.x += 1
			}
		}
	}

	// Assign new position
	character_state.position = newCharacterPosition
}

load_textures :: proc() -> map[string]rl.Texture2D {
	return(
		(map[string]rl.Texture2D) {
			"floor" = rl.LoadTexture("assets/floor.png"),
			"character_front" = rl.LoadTexture("assets/character_front.png"),
			"character_back" = rl.LoadTexture("assets/character_back.png"),
			"enemy_up" = rl.LoadTexture("assets/enemy_up.png"),
			"enemy_down" = rl.LoadTexture("assets/enemy_down.png"),
			"enemy_left" = rl.LoadTexture("assets/enemy_left.png"),
			"enemy_right" = rl.LoadTexture("assets/enemy_right.png"),
		} \
	)
}

handle_input :: proc(
	game_state: ^GameState,
	character_state: ^CharacterState,
	camera: ^rl.Camera2D,
) {
	using rl.KeyboardKey

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

	// Go back to main menu
	if rl.IsKeyPressed(.ESCAPE) {
		game_state.mode = GameMode.MainMenu
	}
}

update_state :: proc(game_state: ^GameState, character_state: ^CharacterState) {
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

handle_enemy_movement :: proc(game_state: ^GameState, enemy_state: ^CharacterState) {
	speedCoefficient: f32
	switch game_state.difficulty {
	case GameDifficulty.Easy:
		{
			speedCoefficient = 1.0
		}
	case GameDifficulty.Medium:
		{
			speedCoefficient = 0.75
		}
	case GameDifficulty.Hard:
		{
			speedCoefficient = 0.5
		}
	}

	isTimeToMove :=
		enemy_state.movement_time_counter > (ENEMY_MOVEMENT_INTERVAL * speedCoefficient)
	if !isTimeToMove do return

	enemy_state.movement_time_counter = 0
	possibleDirections: [dynamic]Direction
	defer delete(possibleDirections)

	currentPosition: TilePosition = {enemy_state.position.x, enemy_state.position.y}
	currentDirection := enemy_state.direction

	// Left
	if is_possible_to_go_direction(game_state, currentPosition, Direction.Left) &&
	   currentDirection != Direction.Right {
		append(&possibleDirections, Direction.Left)
		if currentDirection == Direction.Left {
			append(&possibleDirections, Direction.Left)
		} // Add current direction to the list of possible directions for more chances to keep going straight
	}

	// Up
	if is_possible_to_go_direction(game_state, currentPosition, Direction.Up) &&
	   currentDirection != Direction.Down {
		append(&possibleDirections, Direction.Up)
		if currentDirection == Direction.Up {
			append(&possibleDirections, Direction.Up)
		} // Add current direction to the list of possible directions for more chances to keep going straight
	}

	// Right
	if is_possible_to_go_direction(game_state, currentPosition, Direction.Right) &&
	   currentDirection != Direction.Left {
		append(&possibleDirections, Direction.Right)
		if currentDirection == Direction.Right {
			append(&possibleDirections, Direction.Right)
		} // Add current direction to the list of possible directions for more chances to keep going straight
	}

	// Down
	if is_possible_to_go_direction(game_state, currentPosition, Direction.Down) &&
	   currentDirection != Direction.Up {
		append(&possibleDirections, Direction.Down)
		if currentDirection == Direction.Down {
			append(&possibleDirections, Direction.Down)
		} // Add current direction to the list of possible directions for more chances to keep going straight
	}


	// If there are no possible directions, go back
	if len(possibleDirections) == 0 {
		#partial switch currentDirection {
		case Direction.Up:
			{
				append(&possibleDirections, Direction.Down)
			}
		case Direction.Down:
			{
				append(&possibleDirections, Direction.Up)
			}
		case Direction.Left:
			{
				append(&possibleDirections, Direction.Right)
			}
		case Direction.Right:
			{
				append(&possibleDirections, Direction.Left)
			}
		}
	}

	direction := rand.choice(possibleDirections[:])
	enemy_state.direction = direction

	#partial switch direction {
	case Direction.Up:
		enemy_state.position.y -= 1
	case Direction.Down:
		enemy_state.position.y += 1
	case Direction.Left:
		enemy_state.position.x -= 1
	case Direction.Right:
		enemy_state.position.x += 1
	}
}

floor_texture_source_rect :: proc(char: rune) -> rl.Rectangle {
	return floorTextureSourceRectMap[char]
}

character_texture_source_rect :: proc(character_state: ^CharacterState) -> rl.Rectangle {
	using Direction, CharacterAction

	flipConstant: int
	xPos, yPos: f32
	pose: f32 = f32(character_state.pose % 4)

	#partial switch character_state.direction {
	case .Up:
		{
			flipConstant = -1
			if character_state.action == .Standing {
				yPos = 0
			} else if character_state.action == .Walking {
				yPos = CHARACTER_TEXTURE_SIZE
			}
			xPos = CHARACTER_TEXTURE_SIZE * pose
		}

	case .Down:
		{
			flipConstant = 1
			if character_state.action == .Standing {
				yPos = 0
				if pose == 0 || pose == 1 do xPos = CHARACTER_TEXTURE_SIZE
				else do xPos = CHARACTER_TEXTURE_SIZE * 2
			} else if character_state.action == .Walking {
				yPos = CHARACTER_TEXTURE_SIZE * 2
				switch pose {
				case 0:
					xPos = 0
				case 1:
					xPos = CHARACTER_TEXTURE_SIZE
				case 2:
					xPos = CHARACTER_TEXTURE_SIZE * 2
				case 3:
					xPos = CHARACTER_TEXTURE_SIZE * 3
				}
			}

		}

	case .Left:
		{
			flipConstant = 1
			if character_state.action == .Standing {
				yPos = 0
				switch pose {
				case 0:
					xPos = CHARACTER_TEXTURE_SIZE
				case 1:
					xPos = CHARACTER_TEXTURE_SIZE * 2
				case 2:
					xPos = CHARACTER_TEXTURE_SIZE * 3
				case 3:
					xPos = CHARACTER_TEXTURE_SIZE * 4

				}
			} else if character_state.action == .Walking {
				yPos = CHARACTER_TEXTURE_SIZE
				switch pose {
				case 0:
					xPos = 0
				case 1:
					xPos = CHARACTER_TEXTURE_SIZE
				case 2:
					xPos = CHARACTER_TEXTURE_SIZE * 2
				case 3:
					xPos = CHARACTER_TEXTURE_SIZE * 3
				}
			}
		}

	case .Right:
		{
			flipConstant = -1
			if character_state.action == .Standing {
				yPos = 0
				if pose == 0 || pose == 1 do xPos = CHARACTER_TEXTURE_SIZE
				else do xPos = CHARACTER_TEXTURE_SIZE * 2
			} else if character_state.action == .Walking {
				yPos = CHARACTER_TEXTURE_SIZE * 2
				switch pose {
				case 0:
					xPos = 0
				case 1:
					xPos = CHARACTER_TEXTURE_SIZE
				case 2:
					xPos = CHARACTER_TEXTURE_SIZE * 2
				case 3:
					xPos = CHARACTER_TEXTURE_SIZE * 3
				}
			}
		}
	}

	return(
		rl.Rectangle {
			xPos,
			yPos,
			f32(flipConstant) * CHARACTER_TEXTURE_SIZE,
			CHARACTER_TEXTURE_SIZE,
		} \
	)
}

enemy_texture_source_rect :: proc(character_state: ^CharacterState) -> rl.Rectangle {
	xPos := f32(character_state.pose % 6) * ENEMY_TEXTURE_SIZE
	yPos := f32(character_state.pose / 6) * ENEMY_TEXTURE_SIZE
	return rl.Rectangle{xPos, yPos, ENEMY_TEXTURE_SIZE, ENEMY_TEXTURE_SIZE}
}

draw_normal_mode :: proc(
	game_state: ^GameState,
	character_state: ^CharacterState,
	textureMap: ^map[string]rl.Texture2D,
) {
	for col in 0 ..< GRID_WIDTH {
		for row in 0 ..< GRID_HEIGHT {
			position: ScreenPosition
			position = tile_position_to_screen_position({col, row})

			destRect: rl.Rectangle = rl.Rectangle {
				f32(position.x),
				f32(position.y),
				f32(TEXTURE_WIDTH),
				f32(TEXTURE_HEIGHT),
			}

			rl.DrawTexturePro(
				textureMap["floor"],
				floor_texture_source_rect(game_state.game_map[row][col]),
				destRect,
				rl.Vector2{0.0, 0.0},
				0.0,
				rl.WHITE,
			)
		}
	}

	// Render character

	position := tile_position_to_screen_position(character_state.position, TextureType.Character)

	sourceRect: rl.Rectangle = character_texture_source_rect(character_state)

	destinationRect: rl.Rectangle = rl.Rectangle {
		f32(position.x),
		f32(position.y),
		f32(TEXTURE_WIDTH),
		f32(TEXTURE_HEIGHT),
	}

	characterTextureName := characterDirectionToTextureName[character_state.direction]

	characterTexture := textureMap[characterTextureName]

	rl.DrawTexturePro(
		characterTexture,
		sourceRect,
		destinationRect,
		rl.Vector2{0.0, 0.0},
		0.0,
		rl.WHITE,
	)

	// Render enemies
	for i in 0 ..< gameDifficultyToNumberOfEnemies[game_state.difficulty] {
		enemy_state := game_state.enemies[i]
		position := tile_position_to_screen_position(enemy_state.position, TextureType.Enemy)

		sourceRect: rl.Rectangle = enemy_texture_source_rect(&enemy_state)

		destinationRect: rl.Rectangle = rl.Rectangle {
			f32(position.x),
			f32(position.y),
			f32(TEXTURE_WIDTH),
			f32(TEXTURE_HEIGHT),
		}

		enemyTextureName := enemyDirectionToTextureName[enemy_state.direction]

		enemyTexture := textureMap[enemyTextureName]

		rl.DrawTexturePro(
			enemyTexture,
			sourceRect,
			destinationRect,
			rl.Vector2{0.0, 0.0},
			0.0,
			rl.WHITE,
		)
	}

	// Draw collectible
	position = tile_position_to_screen_position(game_state.collectible_position)

	rl.DrawCircle(
		i32(position.x + TEXTURE_WIDTH / 2),
		i32(position.y + TEXTURE_HEIGHT / 4),
		f32(TEXTURE_WIDTH / 6),
		rl.RED,
	)


	// Update Score
	if game_state.counter > 1.0 {
		game_state.counter = 0.0
		game_state.score += 1 * game_state.score_coefficient
	}

	// Render Score
	text := strings.concatenate({"Score: ", int_to_string(game_state.score)})
	// text := strings.concatenate({"Score: "})
	textC := strings.unsafe_string_to_cstring(text)
	// textC := f32_to_cstring(game_state.counter / 60)
	textWidth := rl.MeasureText(textC, 20)
	rl.DrawText(textC, WINDOW_WIDTH / 2 - textWidth - 10, 10, 20, rl.BLACK)
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

draw_tile_editor_mode :: proc(game_state: ^GameState, texture_map: ^map[string]rl.Texture2D) {
	for col in 0 ..< GRID_WIDTH {
		for row in 0 ..< GRID_HEIGHT {
			position := tile_position_to_screen_position({col, row})

			destRect: rl.Rectangle = rl.Rectangle {
				f32(position.x),
				f32(position.y),
				f32(TEXTURE_WIDTH),
				f32(TEXTURE_HEIGHT),
			}

			rl.DrawTexturePro(
				texture_map["floor"],
				floor_texture_source_rect(game_state.game_map[row][col]),
				destRect,
				rl.Vector2{0.0, 0.0},
				0.0,
				rl.WHITE,
			)
		}
	}

	// Draw colored rectangle on top of the isometric tile
	position := tile_position_to_screen_position(game_state.tile_edit_position)

	destRect: rl.Rectangle = rl.Rectangle {
		f32(position.x + TEXTURE_WIDTH / 2),
		f32(position.y),
		f32(TEXTURE_WIDTH / 2 * math.sqrt(f16(5))),
		f32(TEXTURE_HEIGHT / 2 * math.sqrt(f16(5))),
	}

	rl.DrawCircle(
		i32(position.x + TEXTURE_WIDTH / 2),
		i32(position.y + TEXTURE_HEIGHT / 4),
		f32(TEXTURE_WIDTH / 6),
		rl.Color{0, 0, 255, 100},
	)
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

handle_input_main_menu :: proc(game_state: ^GameState, character_state: ^CharacterState) {
	using rl.KeyboardKey
	idx := game_state.main_menu_index

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

	game_state.main_menu_index = idx
}

change_difficulty :: proc(game_state: ^GameState) {
	using GameDifficulty

	switch game_state.difficulty {
	case GameDifficulty.Easy:
		game_state.difficulty = GameDifficulty.Medium
	case GameDifficulty.Medium:
		game_state.difficulty = GameDifficulty.Hard
	case GameDifficulty.Hard:
		game_state.difficulty = GameDifficulty.Easy
	}
}

gameDifficultyToString := map[GameDifficulty]string {
	GameDifficulty.Easy   = "Easy",
	GameDifficulty.Medium = "Medium",
	GameDifficulty.Hard   = "Hard",
}

// Draw Main Menu
draw_main_menu :: proc(game_state: ^GameState) {
	textWidth := rl.MeasureText("ISOMETRIC PACMAN", 50)
	rl.DrawText("ISOMETRIC PACMAN", (WINDOW_WIDTH - textWidth) / 2, WINDOW_HEIGHT / 4, 50, rl.RED)

	rectangleColors := [4]rl.Color{rl.BLACK, rl.BLACK, rl.BLACK, rl.BLACK}
	rectangleColors[game_state.main_menu_index] = rl.RED

	rectangleWidth: i32 = WINDOW_WIDTH / 4
	rectangleHeight: i32 = WINDOW_HEIGHT / 12

	rectanglePositionX: i32 = i32(WINDOW_WIDTH / 2)
	rectanglePositionY: i32 = i32(WINDOW_HEIGHT * 3 / 10)

	options := [4]string{"Play Game", "Tile Editor", "Change Difficulty", "Exit"}

	for i in 0 ..< 4 {
		rectanglePositionY += rectangleHeight * 3 / 2

		rl.DrawRectangle(
			rectanglePositionX - rectangleWidth / 2,
			rectanglePositionY,
			rectangleWidth,
			rectangleHeight,
			rectangleColors[i],
		)

		text := options[i]

		if i == 2 {
			text = strings.concatenate(
				{"Change Difficulty: ", gameDifficultyToString[game_state.difficulty]},
			)
		}

		textC: cstring = strings.unsafe_string_to_cstring(text)
		textWidth := rl.MeasureText(textC, 20)

		rl.DrawText(
			textC,
			WINDOW_WIDTH / 2 - textWidth / 2,
			rectanglePositionY + rectangleHeight / 2 - 10,
			20,
			rl.RAYWHITE,
		)
	}
}

draw_game_over :: proc(game_state: ^GameState) {
	// Draw GAME OVER text
	textWidth := rl.MeasureText("GAME OVER", 50)
	rl.DrawText("GAME OVER", (WINDOW_WIDTH - textWidth) / 2, WINDOW_HEIGHT / 4, 50, rl.RED)

	// Draw score
	text := strings.concatenate({"Score: ", int_to_string(game_state.score)})
	textC: cstring = strings.unsafe_string_to_cstring(text)
	textWidth = rl.MeasureText(textC, 30)
	rl.DrawText(textC, (WINDOW_WIDTH - textWidth) / 2, WINDOW_HEIGHT / 2, 30, rl.BLACK)

	// Draw number of collected
	text = strings.concatenate(
		{"Collected: ", int_to_string(game_state.collected_count), " items."},
	)
	textC = strings.unsafe_string_to_cstring(text)
	textWidth = rl.MeasureText(textC, 30)
	rl.DrawText(textC, (WINDOW_WIDTH - textWidth) / 2, WINDOW_HEIGHT / 2 + 45, 30, rl.BLACK)

	// Draw total duration
	text = strings.concatenate(
		{"Total Time: ", int_to_string(int(game_state.total_duration)), " seconds."},
	)
	textC = strings.unsafe_string_to_cstring(text)
	textWidth = rl.MeasureText(textC, 30)
	rl.DrawText(textC, (WINDOW_WIDTH - textWidth) / 2, WINDOW_HEIGHT / 2 + 90, 30, rl.BLACK)
}

reset_game :: proc(game_state: ^GameState, character_state: ^CharacterState) {
	game_state.score = 0
	game_state.main_menu_index = 0
	game_state.counter = 0.0
	game_state.total_duration = 0.0
	game_state.collected_count = 0
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

gameDifficultyToNumberOfEnemies := map[GameDifficulty]int {
	GameDifficulty.Easy   = 4,
	GameDifficulty.Medium = 6,
	GameDifficulty.Hard   = 8,
}
