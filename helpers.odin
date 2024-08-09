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
		for col in 0 ..< GRID_WIDTH {
			rune_array: []rune = {game_state.game_map[row][col]}
			game_map_string = strings.concatenate(
				{game_map_string, utf8.runes_to_string(rune_array)},
			)
		}
		game_map_string = strings.concatenate({game_map_string, "\n"})
	}
	data: []u8 = transmute([]u8)game_map_string

	if os.write_entire_file(filepath, data) do fmt.println("File written successfully")
	else do fmt.println("Could not write file")
}

// A hash-map of rune to Rectangle
sourceRectMap := map[rune]rl.Rectangle {
	'O' = rl.Rectangle{0.0, 0.0, MAP_TEXTURE_SIZE, MAP_TEXTURE_SIZE},
	'|' = rl.Rectangle{MAP_TEXTURE_SIZE, 0.0, MAP_TEXTURE_SIZE, MAP_TEXTURE_SIZE},
	'-' = rl.Rectangle{MAP_TEXTURE_SIZE * 2, 0.0, MAP_TEXTURE_SIZE, MAP_TEXTURE_SIZE},
	'{' = rl.Rectangle{MAP_TEXTURE_SIZE * 3, 0.0, MAP_TEXTURE_SIZE, MAP_TEXTURE_SIZE},
	']' = rl.Rectangle{MAP_TEXTURE_SIZE * 4, 0.0, MAP_TEXTURE_SIZE, MAP_TEXTURE_SIZE},
	'}' = rl.Rectangle{MAP_TEXTURE_SIZE * 5, 0.0, MAP_TEXTURE_SIZE, MAP_TEXTURE_SIZE},
	'[' = rl.Rectangle{MAP_TEXTURE_SIZE * 6, 0.0, MAP_TEXTURE_SIZE, MAP_TEXTURE_SIZE},
	'J' = rl.Rectangle{MAP_TEXTURE_SIZE * 7, 0.0, MAP_TEXTURE_SIZE, MAP_TEXTURE_SIZE},
	'Z' = rl.Rectangle{MAP_TEXTURE_SIZE * 8, 0.0, MAP_TEXTURE_SIZE, MAP_TEXTURE_SIZE},
	'L' = rl.Rectangle{MAP_TEXTURE_SIZE * 9, 0.0, MAP_TEXTURE_SIZE, MAP_TEXTURE_SIZE},
	'T' = rl.Rectangle{0.0, MAP_TEXTURE_SIZE, MAP_TEXTURE_SIZE, MAP_TEXTURE_SIZE},
	'X' = rl.Rectangle{MAP_TEXTURE_SIZE, MAP_TEXTURE_SIZE, MAP_TEXTURE_SIZE, MAP_TEXTURE_SIZE},
	'E' = rl.Rectangle{MAP_TEXTURE_SIZE * 2, MAP_TEXTURE_SIZE, MAP_TEXTURE_SIZE, MAP_TEXTURE_SIZE},
	'U' = rl.Rectangle{MAP_TEXTURE_SIZE * 3, MAP_TEXTURE_SIZE, MAP_TEXTURE_SIZE, MAP_TEXTURE_SIZE},
	'D' = rl.Rectangle{MAP_TEXTURE_SIZE * 4, MAP_TEXTURE_SIZE, MAP_TEXTURE_SIZE, MAP_TEXTURE_SIZE},
	'A' = rl.Rectangle{MAP_TEXTURE_SIZE * 5, MAP_TEXTURE_SIZE, MAP_TEXTURE_SIZE, MAP_TEXTURE_SIZE},
}


tilePositionToScreenPosition :: proc(position: Position) -> (f32, f32) {
	x := f32(position.x - position.y) * (TEXTURE_WIDTH / 2)
	y := f32(position.x + position.y) * (TEXTURE_HEIGHT / 4)
	return x, y
}

characterTilePositionToScreenPosition :: proc(position: Position) -> (f32, f32) {
	x := f32(position.x - position.y) * (TEXTURE_WIDTH / 2)
	y :=
		f32(position.x + position.y) * (TEXTURE_HEIGHT / 4) -
		TEXTURE_HEIGHT / 2 -
		TEXTURE_HEIGHT / 8
	return x, y
}

enemyTilePositionToScreenPosition :: proc(position: Position) -> (f32, f32) {
	x := f32(position.x - position.y) * (TEXTURE_WIDTH / 2)
	y := f32(position.x + position.y) * (TEXTURE_HEIGHT / 4) - TEXTURE_HEIGHT / 4
	return x, y
}

characterPoseTextureMap := map[int]rl.Rectangle {
	0 = rl.Rectangle {
		0.0,
		CHARACTER_TEXTURE_SIZE * 2,
		CHARACTER_TEXTURE_SIZE,
		CHARACTER_TEXTURE_SIZE,
	},
	1 = rl.Rectangle {
		CHARACTER_TEXTURE_SIZE,
		CHARACTER_TEXTURE_SIZE * 2,
		CHARACTER_TEXTURE_SIZE,
		CHARACTER_TEXTURE_SIZE,
	},
	2 = rl.Rectangle {
		CHARACTER_TEXTURE_SIZE * 2,
		CHARACTER_TEXTURE_SIZE * 2,
		CHARACTER_TEXTURE_SIZE,
		CHARACTER_TEXTURE_SIZE,
	},
	3 = rl.Rectangle {
		CHARACTER_TEXTURE_SIZE * 3,
		CHARACTER_TEXTURE_SIZE * 2,
		CHARACTER_TEXTURE_SIZE,
		CHARACTER_TEXTURE_SIZE,
	},
}

handleCharacterMovement :: proc(
	character_state: ^CharacterState,
	game_state: ^GameState,
) -> Position {
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

	return newCharacterPosition
}


loadTextures :: proc() -> map[string]rl.Texture2D {
	return (map[string]rl.Texture2D) {
		"floor" = rl.LoadTexture("assets/floor.png"),
		"character_front" = rl.LoadTexture("assets/character_front.png"),
		"character_back" = rl.LoadTexture("assets/character_back.png"),
		"enemy_up" = rl.LoadTexture("assets/enemy_up.png"),
		"enemy_down" = rl.LoadTexture("assets/enemy_down.png"),
		"enemy_left" = rl.LoadTexture("assets/enemy_left.png"),
		"enemy_right" = rl.LoadTexture("assets/enemy_right.png"),
	}
}

handleInput :: proc(
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
		game_state.game_mode = GameMode.TileEditor
	}

	if character_on_the_move do character_state.position = handleCharacterMovement(character_state, game_state)

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
}

updateCharacterAndEnemiesState :: proc(game_state: ^GameState, character_state: ^CharacterState) {
	delta_time := rl.GetFrameTime()

	// Update character state
	character_state.movement_time_counter += delta_time
	character_state.pose_time_counter += delta_time

	if character_state.pose_time_counter > CHARACTER_POSE_INTERVAL {
		character_state.pose_time_counter = 0.0
		character_state.pose += 1
	}

	// Update enemies state
	for i in 0 ..< 4 {
		enemy_state := &game_state.enemies[i]
		enemy_state.movement_time_counter += delta_time
		enemy_state.pose_time_counter += delta_time

		if enemy_state.pose_time_counter > ENEMY_POSE_INTERVAL {
			enemy_state.pose_time_counter = 0.0
			enemy_state.pose += 1
		}

		handleEnemyMovement(game_state, enemy_state)
	}
}

handleEnemyMovement :: proc(game_state: ^GameState, enemy_state: ^CharacterState) {
	isTimeToMove := enemy_state.movement_time_counter > ENEMY_MOVEMENT_INTERVAL
	if !isTimeToMove do return

	enemy_state.movement_time_counter = 0
	possibleDirections: [dynamic]Direction
	defer delete(possibleDirections)

	col, row := enemy_state.position.x, enemy_state.position.y
	// Top
	if row > 0 && game_state.game_map_boolean[row - 1][col] {
		append(&possibleDirections, Direction.Up)
	}
	// Right
	if row < GRID_WIDTH - 1 && game_state.game_map_boolean[row][col + 1] {
		append(&possibleDirections, Direction.Right)
	}
	// Down
	if row < GRID_HEIGHT - 1 && game_state.game_map_boolean[row + 1][col] {
		append(&possibleDirections, Direction.Down)
	}
	// Left
	if row > 0 && game_state.game_map_boolean[row][col - 1] {
		append(&possibleDirections, Direction.Left)
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

floorTextureSourceRect :: proc(char: rune) -> rl.Rectangle {
	return sourceRectMap[char]
}

characterTextureSourceRect :: proc(character_state: ^CharacterState) -> rl.Rectangle {
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

	return rl.Rectangle {
		xPos,
		yPos,
		f32(flipConstant) * CHARACTER_TEXTURE_SIZE,
		CHARACTER_TEXTURE_SIZE,
	}
}

enemyDirectionToTextureName: map[Direction]string = {
	Direction.Up    = "enemy_up",
	Direction.Down  = "enemy_down",
	Direction.Left  = "enemy_left",
	Direction.Right = "enemy_right",
}

characterDirectionToTextureName: map[Direction]string = {
	Direction.Up    = "character_back",
	Direction.Down  = "character_front",
	Direction.Left  = "character_back",
	Direction.Right = "character_front",
}

enemyTextureSourceRect :: proc(character_state: ^CharacterState) -> rl.Rectangle {
	xPos := f32(character_state.pose % 6) * ENEMY_TEXTURE_SIZE
	yPos := f32(character_state.pose / 6) * ENEMY_TEXTURE_SIZE
	return rl.Rectangle{xPos, yPos, ENEMY_TEXTURE_SIZE, ENEMY_TEXTURE_SIZE}
}

textureSourceRect :: proc {
	floorTextureSourceRect,
	characterTextureSourceRect,
}

drawNormalMode :: proc(
	game_state: ^GameState,
	character_state: ^CharacterState,
	textureMap: ^map[string]rl.Texture2D,
) {
	for col in 0 ..< GRID_WIDTH {
		for row in 0 ..< GRID_HEIGHT {
			x, y := tilePositionToScreenPosition({col, row})

			destRect: rl.Rectangle = rl.Rectangle {
				f32(x),
				f32(y),
				f32(TEXTURE_WIDTH),
				f32(TEXTURE_HEIGHT),
			}

			rl.DrawTexturePro(
				textureMap["floor"],
				textureSourceRect(game_state.game_map[row][col]),
				destRect,
				rl.Vector2{0.0, 0.0},
				0.0,
				rl.WHITE,
			)
		}
	}

	// Render character
	x, y := characterTilePositionToScreenPosition(character_state.position)

	sourceRect: rl.Rectangle = textureSourceRect(character_state)

	destinationRect: rl.Rectangle = rl.Rectangle {
		f32(x),
		f32(y),
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
	for i in 0 ..< 4 {
		enemy_state := game_state.enemies[i]
		x, y := enemyTilePositionToScreenPosition(enemy_state.position)

		sourceRect: rl.Rectangle = enemyTextureSourceRect(&enemy_state)

		destinationRect: rl.Rectangle = rl.Rectangle {
			f32(x),
			f32(y),
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
}

f32_to_cstring :: proc(f: f32) -> cstring {
	builder := strings.builder_make()
	strings.write_f32(&builder, f, 'f')
	return strings.to_cstring(&builder)
}


handleInputForTileEditor :: proc(game_state: ^GameState, camera: ^rl.Camera2D) {
	using rl.KeyboardKey

	// Change game mode
	if rl.IsKeyPressed(.M) {
		write_map(game_state, "assets/map.txt")
		game_state.game_mode = GameMode.Normal
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
	if rl.IsKeyPressed(.SPACE) do updateTileAndNeighbors(game_state, game_state.tile_edit_position)
}

updateTileAndNeighbors :: proc(game_state: ^GameState, position: Position) {
	x, y := position.x, position.y
	if game_state.game_map_boolean[y][x] {
		game_state.game_map[y][x] = 'O'
		game_state.game_map_boolean[y][x] = false
		return
	}

	// Call updateTile for self
	updateTile(game_state, {x, y})

	// Call updateTile for all neighbors
	if x > 0 && game_state.game_map_boolean[y][x - 1] do updateTile(game_state, {position.x - 1, position.y}) // Left
	if y > 0 && game_state.game_map_boolean[y - 1][x] do updateTile(game_state, {position.x, position.y - 1}) // Top
	if x < GRID_WIDTH - 1 && game_state.game_map_boolean[y][x + 1] do updateTile(game_state, {position.x + 1, position.y}) // Right
	if y < GRID_HEIGHT - 1 && game_state.game_map_boolean[y + 1][x] do updateTile(game_state, {position.x, position.y + 1}) // Down
}

updateTile :: proc(game_state: ^GameState, position: Position) {
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

drawTileEditorMode :: proc(
	game_state: ^GameState,
	character_state: ^CharacterState,
	texture_map: ^map[string]rl.Texture2D,
) {
	for col in 0 ..< GRID_WIDTH {
		for row in 0 ..< GRID_HEIGHT {
			x, y := tilePositionToScreenPosition({col, row})

			destRect: rl.Rectangle = rl.Rectangle {
				f32(x),
				f32(y),
				f32(TEXTURE_WIDTH),
				f32(TEXTURE_HEIGHT),
			}

			rl.DrawTexturePro(
				texture_map["floor"],
				textureSourceRect(game_state.game_map[row][col]),
				destRect,
				rl.Vector2{0.0, 0.0},
				0.0,
				rl.WHITE,
			)
		}
	}

	// Draw colored rectangle on top of the isometric tile
	x, y := tilePositionToScreenPosition(game_state.tile_edit_position)

	destRect: rl.Rectangle = rl.Rectangle {
		f32(x + TEXTURE_WIDTH / 2),
		f32(y),
		f32(TEXTURE_WIDTH / 2 * math.sqrt(f16(5))),
		f32(TEXTURE_HEIGHT / 2 * math.sqrt(f16(5))),
	}

	// rl.DrawRectanglePro(destRect, rl.Vector2{0.0, 0.0}, 63.4, rl.Color{255, 0, 0, 100})
	rl.DrawCircle(
		i32(x + TEXTURE_WIDTH / 2),
		i32(y + TEXTURE_HEIGHT / 4),
		f32(TEXTURE_WIDTH / 6),
		rl.Color{0, 0, 255, 100},
	)
}

updateCamera :: proc(character_state: ^CharacterState, camera: ^rl.Camera2D) {
	xPos, yPos := characterTilePositionToScreenPosition(character_state.position)
	camera.target = rl.Vector2{f32(xPos), f32(yPos)}
}

initializeEnemies :: proc() -> [4]CharacterState {
	enemies: [4]CharacterState
	for i in 0 ..< 4 {
		enemies[i] = {
			pose                  = 0,
			pose_time_counter     = 0.0,
			movement_time_counter = 0.0,
			action                = CharacterAction.Standing,
			position              = {i + 1, i + 1},
			direction             = Direction.Down,
		}
	}

	return enemies
}

placeCharacters :: proc(game_state: ^GameState, character_state: ^CharacterState) {
	available_positions: [dynamic]Position
	defer delete(available_positions)

	for row in 0 ..< GRID_HEIGHT {
		for col in 0 ..< GRID_WIDTH {
			if game_state.game_map_boolean[row][col] {
				append(&available_positions, Position{col, row})
			}
		}
	}

	// Place character
	idx := rand.int31() % i32(len(available_positions))
	character_state.position = available_positions[idx]
	unordered_remove(&available_positions, int(idx))

	// Place enemies
	for i in 0 ..< 4 {
		idx := rand.int31() % i32(len(available_positions))
		game_state.enemies[i].position = available_positions[idx]
		unordered_remove(&available_positions, int(idx))
	}
}
