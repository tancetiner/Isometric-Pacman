package main

import "core:fmt"
import "core:math"
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


directionToTextureIdx: map[Direction]int = {
	Direction.Up    = 1,
	Direction.Down  = 0,
	Direction.Left  = 1,
	Direction.Right = 0,
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
		"house" = rl.LoadTexture("assets/house.png"),
		"box" = rl.LoadTexture("assets/box.png"),
		"car" = rl.LoadTexture("assets/car.png"),
		"stone" = rl.LoadTexture("assets/stone.png"),
		"character_front" = rl.LoadTexture("assets/character_front.png"),
		"character_back" = rl.LoadTexture("assets/character_back.png"),
	}
}

handleInput :: proc(
	game_state: ^GameState,
	character_state: ^CharacterState,
	camera: ^rl.Camera2D,
) {
	using rl.KeyboardKey

	// Character Movement
	isTimeToMove := character_state.movement_time_counter > MOVEMENT_FREQUENCY
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

	// if rl.IsKeyDown(.RIGHT) {
	// 	if character_state.direction != Direction.Right || isTimeToMove {
	// 		if character_state.direction != Direction.Right do character_state.movement_time_counter = 0.0
	// 		character_state.direction = Direction.Right
	// 		character_on_the_move = true
	// 	}} else if rl.IsKeyDown(.LEFT) {
	// 	if character_state.direction != Direction.Left || isTimeToMove {
	// 		if character_state.direction != Direction.Left do character_state.movement_time_counter = 0.0
	// 		character_state.direction = Direction.Left
	// 		character_on_the_move = true
	// 	}} else if rl.IsKeyDown(.UP) {
	// 	if character_state.direction != Direction.Up || isTimeToMove {
	// 		if character_state.direction != Direction.Up do character_state.movement_time_counter = 0.0
	// 		character_state.direction = Direction.Up
	// 		character_on_the_move = true
	// 	}} else if rl.IsKeyDown(.DOWN) {
	// 	if character_state.direction != Direction.Down || isTimeToMove {
	// 		if character_state.direction != Direction.Down do character_state.movement_time_counter = 0.0
	// 		character_state.direction = Direction.Down
	// 		character_on_the_move = true
	// 	}} else if rl.IsKeyPressed(.M) do game_state.game_mode = GameMode.TileEditor

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

updateCharacterState :: proc(character_state: ^CharacterState) {
	character_state.movement_time_counter += rl.GetFrameTime()
	character_state.pose_time_counter += rl.GetFrameTime()

	if character_state.pose_time_counter > 0.25 {
		character_state.pose_time_counter = 0.0
		character_state.pose += 1
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

	characterTexture :=
		character_state.direction == Direction.Down ||
		character_state.direction == Direction.Right \
		? textureMap["character_front"] \
		: textureMap["character_back"]

	rl.DrawTexturePro(
		characterTexture,
		sourceRect,
		destinationRect,
		rl.Vector2{0.0, 0.0},
		0.0,
		rl.WHITE,
	)
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
	xPos, yPos := game_state.tile_edit_position[0], game_state.tile_edit_position[1]
	if rl.IsKeyPressed(.UP) && xPos > 0 do game_state.tile_edit_position[0] -= 1
	else if rl.IsKeyPressed(.DOWN) && xPos < GRID_HEIGHT - 1 do game_state.tile_edit_position[0] += 1
	else if rl.IsKeyPressed(.LEFT) && yPos > 0 do game_state.tile_edit_position[1] -= 1
	else if rl.IsKeyPressed(.RIGHT) && yPos < GRID_WIDTH - 1 do game_state.tile_edit_position[1] += 1

	// Change tile
	if rl.IsKeyPressed(.SPACE) do updateTileAndNeighbors(game_state, game_state.tile_edit_position)
}

updateTileAndNeighbors :: proc(game_state: ^GameState, position: [2]int) {
	x, y := position.x, position.y
	if game_state.game_map_boolean[x][y] {
		game_state.game_map[x][y] = 'O'
		game_state.game_map_boolean[x][y] = false
		return
	}

	// Call updateTile for self
	updateTile(game_state, position)

	// Call updateTile for all neighbors
	if y > 0 && game_state.game_map_boolean[x][y - 1] do updateTile(game_state, {x, y - 1})
	if x > 0 && game_state.game_map_boolean[x - 1][y] do updateTile(game_state, {x - 1, y})
	if y < GRID_WIDTH - 1 && game_state.game_map_boolean[x][y + 1] do updateTile(game_state, {x, y + 1})
	if x < GRID_HEIGHT - 1 && game_state.game_map_boolean[x + 1][y] do updateTile(game_state, {x + 1, y})
}

updateTile :: proc(game_state: ^GameState, position: Position) {
	x, y := position.x, position.y

	isNeighborOccupied: [4]bool

	// Left
	if y > 0 && game_state.game_map_boolean[x][y - 1] do isNeighborOccupied[0] = true
	// Top
	if x > 0 && game_state.game_map_boolean[x - 1][y] do isNeighborOccupied[1] = true
	// Right
	if y < GRID_WIDTH - 1 && game_state.game_map_boolean[x][y + 1] do isNeighborOccupied[2] = true
	// Down
	if x < GRID_HEIGHT - 1 && game_state.game_map_boolean[x + 1][y] do isNeighborOccupied[3] = true

	switch isNeighborOccupied {
	case {false, false, false, false}:
		game_state.game_map[x][y] = 'X'
	case {true, false, false, false}:
		game_state.game_map[x][y] = '-'
	case {false, true, false, false}:
		game_state.game_map[x][y] = '|'
	case {false, false, true, false}:
		game_state.game_map[x][y] = '-'
	case {false, false, false, true}:
		game_state.game_map[x][y] = '|'
	case {true, true, false, false}:
		game_state.game_map[x][y] = ']'
	case {true, false, true, false}:
		game_state.game_map[x][y] = '-'
	case {true, false, false, true}:
		game_state.game_map[x][y] = '}'
	case {false, true, true, false}:
		game_state.game_map[x][y] = '['
	case {false, true, false, true}:
		game_state.game_map[x][y] = '|'
	case {false, false, true, true}:
		game_state.game_map[x][y] = '{'
	case {true, true, true, false}:
		game_state.game_map[x][y] = 'Z'
	case {true, true, false, true}:
		game_state.game_map[x][y] = 'J'
	case {true, false, true, true}:
		game_state.game_map[x][y] = 'T'
	case {false, true, true, true}:
		game_state.game_map[x][y] = 'L'
	case {true, true, true, true}:
		game_state.game_map[x][y] = 'X'
	}

	game_state.game_map_boolean[x][y] = true
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
