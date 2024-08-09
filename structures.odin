package main
import rl "vendor:raylib"

Direction :: enum {
	None,
	Up,
	Down,
	Left,
	Right,
}

CharacterAction :: enum {
	Walking,
	Talking,
	Standing,
}

GameMode :: enum {
	Normal,
	TileEditor,
}

GameState :: struct {
	game_mode:          GameMode,
	game_map:           [GRID_HEIGHT][GRID_WIDTH]rune,
	game_map_boolean:   [GRID_HEIGHT][GRID_WIDTH]bool,
	tile_edit_position: Position,
	enemies:            [4]CharacterState,
}

Position :: [2]int

CharacterState :: struct {
	pose:                  int,
	pose_time_counter:     f32,
	movement_time_counter: f32,
	action:                CharacterAction,
	position:              Position,
	direction:             Direction,
}

MapState :: struct {
	map_texture:     rl.Texture2D,
	source_rect_map: map[rune]rl.Rectangle,
}
