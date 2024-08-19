# Isometric Pacman

## Description

Isometric Pacman is a simple Pacman clone featuring isometric rendering, built to familiarize with the "Odin Language + Raylib" stack for game development.

## Motivation

The project aims to explore game development using the Odin Language and Raylib by creating a classic game with an isometric twist.

## Features

### Implemented Features

- **Character Movement:** The character can move around the map if there is a path.
- **Map Editing:** The game includes an edit map mode where new paths can be inserted and existing ones can be deleted.
- **Enemies and Placements:** Implemented a set of enemies (changes depending on the difficulty), each with its own `CharacterState`. A mechanism for placing enemies randomly on the map is implemented.
- **Difficulty Levels:** Easy, medium, and hard difficulty settings affect the number and speed of enemies.
- **Collectible Objects:** Randomly placed objects that grant points when collected.
- **Scoring Mechanism:** Score depends on the time and the number of collected items.
- **High Score:** Tracks the high score per difficulty with read/write JSON file operations.

## Installation

To play or develop Isometric Pacman, follow these steps:

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/isometric-pacman.git
   ```
2. Ensure you have the Odin Language compiler installed. (Raylib comes out-of-the-box in Odin language). For installation instructions, refer to [here](https://odin-lang.org/docs/install/).
3. Navigate to the project directory:
   ```bash
   cd isometric-pacman
   ```
4. Build and run the game:
   ```bash
   odin run .
   ```

## Acknowledgements

Special thanks to the creators who provided free textures that greatly enhanced the development of this game:

- **Frog Character:** [Animated RPG Frog Character by penzilla](https://penzilla.itch.io/animated-rpg-frog-character)
- **Enemy Characters (Fox):** [8 Directional Fox Character by hormelz](https://hormelz.itch.io/8-directional-fox-character)
- **Floor Textures:** [Isometric Village by xilurus](https://xilurus.itch.io/isometric-village)
