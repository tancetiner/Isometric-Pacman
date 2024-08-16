package main

import "core:math"
import "core:strings"
import rl "vendor:raylib"

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

draw_main_menu :: proc(game_state: ^GameState) {
	textWidth := rl.MeasureText("ISOMETRIC PACMAN", 50)
	rl.DrawText("ISOMETRIC PACMAN", (WINDOW_WIDTH - textWidth) / 2, WINDOW_HEIGHT / 4, 50, rl.RED)

	rectangleColors := [4]rl.Color{rl.BLACK, rl.BLACK, rl.BLACK, rl.BLACK}
	rectangleColors[game_state.menu_index] = rl.RED

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

	// Draw high scores
	if len(game_state.high_scores) != 0 {
		text := strings.concatenate(
			 {
				"High Scores\n\n\n",
				"Easy: ",
				int_to_string(game_state.high_scores[GameDifficulty.Easy]),
				"\n\n",
				"Medium: ",
				int_to_string(game_state.high_scores[GameDifficulty.Medium]),
				"\n\n",
				"Hard: ",
				int_to_string(game_state.high_scores[GameDifficulty.Hard]),
			},
		)
		textC: cstring = strings.unsafe_string_to_cstring(text)
		textWidth = rl.MeasureText(textC, 20)
		rl.DrawText(textC, WINDOW_WIDTH - textWidth - 10, WINDOW_HEIGHT - 140, 20, rl.BLACK)
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

	// Draw NEW RECORD if it is a new record
	if len(game_state.high_scores) != 0 &&
	   game_state.score > game_state.high_scores[game_state.difficulty] {
		textWidth = rl.MeasureText("NEW HIGH SCORE", 50)
		rl.DrawText(
			"NEW HIGH SCORE",
			(WINDOW_WIDTH - textWidth) / 2,
			WINDOW_HEIGHT / 2 + 135,
			50,
			rl.RED,
		)
	}
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

	// Pause Menu
	if game_state.is_paused {
		horizontalOffset: i32 = -WINDOW_WIDTH / 2
		rectangleColors := [3]rl.Color{rl.BLACK, rl.BLACK, rl.BLACK}
		rectangleColors[game_state.menu_index] = rl.RED

		// Draw the menu
		rl.DrawRectangle(
			horizontalOffset + WINDOW_WIDTH / 4,
			WINDOW_HEIGHT / 4,
			WINDOW_WIDTH / 2,
			WINDOW_HEIGHT / 2,
			rl.Fade(rl.BLACK, 0.8),
		)
		rl.DrawRectangleLines(
			horizontalOffset + WINDOW_WIDTH / 4,
			WINDOW_HEIGHT / 4,
			WINDOW_WIDTH / 2,
			WINDOW_HEIGHT / 2,
			rl.BLACK,
		)

		textWidth = rl.MeasureText("PAUSED", 40)
		rl.DrawText(
			"PAUSED",
			horizontalOffset + WINDOW_WIDTH / 2 - textWidth / 2,
			WINDOW_HEIGHT / 2 - 80,
			40,
			rl.RED,
		)

		// Draw the options
		textWidth = rl.MeasureText("Resume", 20)
		rl.DrawText(
			"Resume",
			horizontalOffset + WINDOW_WIDTH / 2 - textWidth / 2,
			WINDOW_HEIGHT / 2 - 30,
			20,
			rectangleColors[0],
		)

		textWidth = rl.MeasureText("Restart", 20)
		rl.DrawText(
			"Restart",
			horizontalOffset + WINDOW_WIDTH / 2 - textWidth / 2,
			WINDOW_HEIGHT / 2,
			20,
			rectangleColors[1],
		)

		textWidth = rl.MeasureText("To Main Menu", 20)
		rl.DrawText(
			"To Main Menu",
			horizontalOffset + WINDOW_WIDTH / 2 - textWidth / 2,
			WINDOW_HEIGHT / 2 + 30,
			20,
			rectangleColors[2],
		)
	}
}
