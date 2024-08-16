package main

import rl "vendor:raylib"

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
