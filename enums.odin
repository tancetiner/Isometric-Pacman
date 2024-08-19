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
	EditMap,
	ShowHelp,
	GameOver,
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
