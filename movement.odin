package main

import "core:math/rand"

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
