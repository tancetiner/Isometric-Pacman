package main
import rl "vendor:raylib"

TilePosition :: [2]int
ScreenPosition :: [2]f32

GameState :: struct {
	mode:                 GameMode,
	game_map:             [GRID_HEIGHT][GRID_WIDTH]rune,
	game_map_boolean:     [GRID_HEIGHT][GRID_WIDTH]bool,
	tile_edit_position:   TilePosition,
	enemies:              [dynamic]CharacterState,
	main_menu_index:      int,
	difficulty:           GameDifficulty,
	counter:              f32,
	score:                int,
	score_coefficient:    int,
	total_duration:       f32,
	collectible_position: TilePosition,
	collected_count:      int,
	high_scores:          map[GameDifficulty]int,
}

CharacterState :: struct {
	pose:                  int,
	pose_time_counter:     f32,
	movement_time_counter: f32,
	action:                CharacterAction,
	position:              TilePosition,
	direction:             Direction,
}
