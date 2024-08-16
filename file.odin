package main

import "core:c/libc"
import "core:encoding/json"
import "core:fmt"
import "core:os"
import "core:strings"
import "core:unicode/utf8"

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
		rune_array: [dynamic]rune
		for col in 0 ..< GRID_WIDTH {
			append(&rune_array, game_state.game_map[row][col])
		}
		game_map_string = strings.concatenate(
			{game_map_string, utf8.runes_to_string(rune_array[:]), "\n"},
		)
	}
	data: []u8 = transmute([]u8)game_map_string

	if os.write_entire_file(filepath, data) do fmt.println("File written successfully")
	else do fmt.println("Could not write file")
}

read_high_scores :: proc() -> map[GameDifficulty]int {
	emptyMap := map[GameDifficulty]int{}

	if !os.exists("./assets/high_scores.json") {
		fd, err := os.open("./assets/high_scores.json", os.O_CREATE | os.O_WRONLY)

		if err != nil {
			fmt.println("Error creating high scores file")
			return emptyMap
		}
		defer os.close(fd)

		if !write_string_to_json(fd, NEW_HIGH_SCORES_TEXT) do return emptyMap

		libc.system("chmod 644 ./assets/high_scores.json")
	}

	file, err := os.open("assets/high_scores.json", os.O_RDONLY)
	if err != nil {
		return emptyMap
	}
	defer os.close(file)

	data, success := os.read_entire_file(file)

	if !success {
		return emptyMap
	}

	value, error := json.parse(data)

	if error != nil {
		return emptyMap
	}

	json_object, is_object := value.(json.Object)

	if !is_object {
		return emptyMap
	}

	return(
		map[GameDifficulty]int {
			GameDifficulty.Easy = int(json_object["easy"].(json.Float)),
			GameDifficulty.Medium = int(json_object["medium"].(json.Float)),
			GameDifficulty.Hard = int(json_object["hard"].(json.Float)),
		} \
	)
}

write_high_scores :: proc(high_scores: map[GameDifficulty]int) {
	stringBuilder, builderErr := strings.builder_make_none()

	if builderErr != nil {
		return
	}

	// Build the json string with stringBuilder
	strings.write_string(
		&stringBuilder,
		strings.concatenate(
			{"{\n\"easy\": ", int_to_string(high_scores[GameDifficulty.Easy]), ","},
		),
	)
	strings.write_string(
		&stringBuilder,
		strings.concatenate(
			{"\n\"medium\": ", int_to_string(high_scores[GameDifficulty.Medium]), ","},
		),
	)
	strings.write_string(
		&stringBuilder,
		strings.concatenate(
			{"\n\"hard\": ", int_to_string(high_scores[GameDifficulty.Hard]), "\n}"},
		),
	)

	json_string := strings.to_string(stringBuilder)

	file, fileOpenErr := os.open("assets/high_scores.json")

	if fileOpenErr != nil {
		return
	}
	defer os.close(file)

	write_string_to_json(file, json_string)
}

write_string_to_json :: proc(fd: os.Handle, data: string) -> bool {
	_, err := os.write(fd, transmute([]u8)data)
	if err != nil {
		fmt.println("Error writing to high scores file")
		return false
	}

	return true
}
