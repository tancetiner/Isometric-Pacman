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
	MainMenu,
	PlayGame,
	TileEditor,
}

TextureType :: enum {
	Character,
	Enemy,
	Tile,
}

GameDifficulty :: enum {
	Easy,
	Medium,
	Hard,
}
