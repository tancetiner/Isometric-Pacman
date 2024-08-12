package main

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

TextureType :: enum {
	Character,
	Enemy,
	Tile,
}
