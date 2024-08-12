package main
import rl "vendor:raylib"

TilePosition :: [2]int
ScreenPosition :: [2]f32

GameState :: struct {
	game_mode:          GameMode,
	game_map:           [GRID_HEIGHT][GRID_WIDTH]rune,
	game_map_boolean:   [GRID_HEIGHT][GRID_WIDTH]bool,
	tile_edit_position: TilePosition,
	enemies:            [4]CharacterState,
}

CharacterState :: struct {
	pose:                  int,
	pose_time_counter:     f32,
	movement_time_counter: f32,
	action:                CharacterAction,
	position:              TilePosition,
	direction:             Direction,
}
