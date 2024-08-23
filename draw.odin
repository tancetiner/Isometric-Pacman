package main

import "core:math"
import "core:strings"
import rl "vendor:raylib"

draw_edit_map_mode :: proc(game_state: ^GameState, texture_map: ^map[string]rl.Texture2D) {
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

	// Pause Menu
	if game_state.is_paused {
		horizontalOffset: i32 = -CAMERA_HORIZONTAL_OFFSET
		verticalOffset: i32 = -CAMERA_VERTICAL_OFFSET
		rectangleColors := [3]rl.Color{rl.RAYWHITE, rl.RAYWHITE, rl.RAYWHITE}
		rectangleColors[game_state.menu_index] = rl.RED

		rectanglePosY: i32 = WINDOW_HEIGHT / 4
		rectangleHeight: i32 = WINDOW_HEIGHT / 2
		titlePadding: i32 = rectangleHeight / 7
		optionPadding: i32 = titlePadding / 2
		titleFont: i32 = titlePadding
		optionFont: i32 = optionPadding

		// Draw the menu
		rl.DrawRectangle(
			horizontalOffset + WINDOW_WIDTH / 4,
			verticalOffset + rectanglePosY,
			WINDOW_WIDTH / 2,
			rectangleHeight,
			rl.Fade(rl.BLACK, 0.8),
		)

		rl.DrawRectangleLines(
			horizontalOffset + WINDOW_WIDTH / 4,
			verticalOffset + rectanglePosY,
			WINDOW_WIDTH / 2,
			rectangleHeight,
			rl.BLACK,
		)

		textWidth := rl.MeasureText("TILE EDITOR", titleFont)
		rl.DrawText(
			"TILE EDITOR",
			horizontalOffset + WINDOW_WIDTH / 2 - textWidth / 2,
			verticalOffset + rectanglePosY + titlePadding,
			titleFont,
			rl.RED,
		)

		optionsStartPosY := rectanglePosY + titlePadding * 3

		// Draw the options
		textWidth = rl.MeasureText("Resume", optionFont)
		rl.DrawText(
			"Resume",
			horizontalOffset + WINDOW_WIDTH / 2 - textWidth / 2,
			verticalOffset + optionsStartPosY,
			optionFont,
			rectangleColors[0],
		)

		textWidth = rl.MeasureText("Save and Exit", optionFont)
		rl.DrawText(
			"Save and Exit",
			horizontalOffset + WINDOW_WIDTH / 2 - textWidth / 2,
			verticalOffset + optionsStartPosY + optionPadding * 2,
			optionFont,
			rectangleColors[1],
		)

		textWidth = rl.MeasureText("Discard and Exit", optionFont)
		rl.DrawText(
			"Discard and Exit",
			horizontalOffset + WINDOW_WIDTH / 2 - textWidth / 2,
			verticalOffset + optionsStartPosY + optionPadding * 4,
			optionFont,
			rectangleColors[2],
		)
	}
}

draw_main_menu :: proc(game_state: ^GameState) {
	textWidth := rl.MeasureText("ISOMETRIC PACMAN", 50)
	rl.DrawText(
		"ISOMETRIC PACMAN",
		(WINDOW_WIDTH - textWidth) / 2,
		WINDOW_HEIGHT * 2 / 12,
		50,
		rl.RED,
	)

	rectangleColors := [5]rl.Color{rl.BLACK, rl.BLACK, rl.BLACK, rl.BLACK, rl.BLACK}
	rectangleColors[game_state.menu_index] = rl.RED

	rectangleWidth: i32 = WINDOW_WIDTH / 4
	rectangleHeight: i32 = WINDOW_HEIGHT / 12

	rectanglePositionX: i32 = i32(WINDOW_WIDTH / 2)
	rectanglePositionY: i32 = i32(WINDOW_HEIGHT * 5 / 24)

	options := [5]string{"Play Game", "Tile Editor", "Change Difficulty", "How to Play", "Exit"}

	for i in 0 ..< len(options) {
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
	horizontalOffset: i32 = -CAMERA_HORIZONTAL_OFFSET
	verticalOffset: i32 = -CAMERA_VERTICAL_OFFSET
	text := strings.concatenate({"Score: ", int_to_string(game_state.score)})
	textC := strings.unsafe_string_to_cstring(text)
	textWidth := rl.MeasureText(textC, 30)
	rl.DrawText(
		textC,
		horizontalOffset + WINDOW_WIDTH - textWidth - 10,
		verticalOffset + 10,
		30,
		rl.BLACK,
	)

	// Render Score Coefficient
	text = strings.concatenate({"x", int_to_string(game_state.score_coefficient)})
	textC = strings.unsafe_string_to_cstring(text)
	// textWidth = rl.MeasureText(textC, 30)
	rl.DrawText(textC, horizontalOffset + 10, verticalOffset + 10, 30, rl.BLACK)

	// Pause Menu
	if game_state.is_paused {
		horizontalOffset: i32 = -CAMERA_HORIZONTAL_OFFSET
		verticalOffset: i32 = -CAMERA_VERTICAL_OFFSET
		rectangleColors := [4]rl.Color{rl.RAYWHITE, rl.RAYWHITE, rl.RAYWHITE, rl.RAYWHITE}
		rectangleColors[game_state.menu_index] = rl.RED

		rectanglePosY: i32 = WINDOW_HEIGHT / 4
		rectangleHeight: i32 = WINDOW_HEIGHT / 2
		titlePadding: i32 = rectangleHeight / 7
		optionPadding: i32 = titlePadding / 2
		titleFont: i32 = titlePadding
		optionFont: i32 = optionPadding

		// Draw the menu
		rl.DrawRectangle(
			horizontalOffset + WINDOW_WIDTH / 4,
			verticalOffset + rectanglePosY,
			WINDOW_WIDTH / 2,
			rectangleHeight,
			rl.Fade(rl.BLACK, 0.8),
		)

		rl.DrawRectangleLines(
			horizontalOffset + WINDOW_WIDTH / 4,
			verticalOffset + rectanglePosY,
			WINDOW_WIDTH / 2,
			rectangleHeight,
			rl.BLACK,
		)

		textWidth = rl.MeasureText("PAUSED", titleFont)
		rl.DrawText(
			"PAUSED",
			horizontalOffset + WINDOW_WIDTH / 2 - textWidth / 2,
			verticalOffset + rectanglePosY + titlePadding,
			titleFont,
			rl.RED,
		)

		optionsStartPosY := rectanglePosY + titlePadding * 3

		// Draw the options
		textWidth = rl.MeasureText("Resume", optionFont)
		rl.DrawText(
			"Resume",
			horizontalOffset + WINDOW_WIDTH / 2 - textWidth / 2,
			verticalOffset + optionsStartPosY,
			optionFont,
			rectangleColors[0],
		)

		textWidth = rl.MeasureText("Restart", optionFont)
		rl.DrawText(
			"Restart",
			horizontalOffset + WINDOW_WIDTH / 2 - textWidth / 2,
			verticalOffset + optionsStartPosY + optionPadding * 2,
			optionFont,
			rectangleColors[1],
		)

		textWidth = rl.MeasureText("How to Play", optionFont)
		rl.DrawText(
			"How to Play",
			horizontalOffset + WINDOW_WIDTH / 2 - textWidth / 2,
			verticalOffset + optionsStartPosY + optionPadding * 4,
			optionFont,
			rectangleColors[2],
		)

		textWidth = rl.MeasureText("To Main Menu", optionFont)
		rl.DrawText(
			"To Main Menu",
			horizontalOffset + WINDOW_WIDTH / 2 - textWidth / 2,
			verticalOffset + optionsStartPosY + optionPadding * 6,
			optionFont,
			rectangleColors[3],
		)
	}
}

draw_show_help_mode :: proc(game_state: ^GameState) {
	rl.DrawRectangle(0, 0, WINDOW_WIDTH, WINDOW_HEIGHT, rl.Fade(rl.BLACK, 0.8))

	titlePadding: i32 = WINDOW_HEIGHT / 14
	instructionPadding: i32 = titlePadding / 2

	titleFont: i32 = titlePadding
	instructionFont: i32 = instructionPadding

	textC: cstring = "How to Play"
	textWidth: i32 = rl.MeasureText(textC, titleFont)
	rl.DrawText("How to Play", (WINDOW_WIDTH - textWidth) / 2, titlePadding, titleFont, rl.RED)

	instructions: [4]cstring = {
		"- Use the arrow keys to move the character",
		"- Collect the items (red circles) to increase your score",
		"- Avoid the enemies to survive",
		"- Press escape (ESC) to pause the game",
	}

	for instruction, idx in instructions {
		textWidth = rl.MeasureText(instruction, instructionFont)
		rl.DrawText(
			instruction,
			(WINDOW_WIDTH - textWidth) / 2,
			titlePadding * 3 + instructionPadding * 2 * i32(idx),
			instructionFont,
			rl.WHITE,
		)
	}

	textC = "Scoring System"
	textWidth = rl.MeasureText(textC, titleFont)
	rl.DrawText(
		textC,
		(WINDOW_WIDTH - textWidth) / 2,
		titlePadding * 4 + instructionPadding * 7,
		titleFont,
		rl.RED,
	)

	instructions = [4]cstring {
		"- Each second you get 1 point times the score coefficient",
		"- Each collected item gives you 10 points times the score coefficient",
		"- The score coefficient increases every 15 seconds",
		"- The score coefficient is shown in the top right corner (like x3)",
	}

	for instruction, idx in instructions {
		textWidth = rl.MeasureText(instruction, instructionFont)
		rl.DrawText(
			instruction,
			(WINDOW_WIDTH - textWidth) / 2,
			titlePadding * 6 + instructionPadding * 7 + instructionPadding * 2 * i32(idx),
			instructionFont,
			rl.WHITE,
		)
	}
}
