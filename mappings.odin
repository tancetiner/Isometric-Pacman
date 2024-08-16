package main

import rl "vendor:raylib"

// A hash-map of game difficulty to number of enemies
gameDifficultyToNumberOfEnemies := map[GameDifficulty]int {
	GameDifficulty.Easy   = 4,
	GameDifficulty.Medium = 6,
	GameDifficulty.Hard   = 8,
}

// A hash-map of game difficulty to their string representation
gameDifficultyToString := map[GameDifficulty]string {
	GameDifficulty.Easy   = "Easy",
	GameDifficulty.Medium = "Medium",
	GameDifficulty.Hard   = "Hard",
}

// A hash-map of floor type (specified with runes) to texture source rectangles
floorTextureSourceRectMap := map[rune]rl.Rectangle {
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

// A hash-map of character pose to texture source rectangles
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

// A hash-map of enemy direction to texture file name
enemyDirectionToTextureName: map[Direction]string = {
	Direction.Up    = "enemy_up",
	Direction.Down  = "enemy_down",
	Direction.Left  = "enemy_left",
	Direction.Right = "enemy_right",
}

// A hash-map of character direction to texture file name
characterDirectionToTextureName: map[Direction]string = {
	Direction.Up    = "character_back",
	Direction.Down  = "character_front",
	Direction.Left  = "character_back",
	Direction.Right = "character_front",
}
