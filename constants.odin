package main

WINDOW_WIDTH :: 1200
WINDOW_HEIGHT :: 800
CAMERA_HORIZONTAL_OFFSET :: WINDOW_WIDTH / 2
CAMERA_VERTICAL_OFFSET :: -WINDOW_HEIGHT / 2
GRID_WIDTH :: 48
GRID_HEIGHT :: 48
FPS :: 60
TEXTURE_WIDTH :: 64
TEXTURE_HEIGHT :: 64
MAP_TEXTURE_SIZE :: 256.0
CHARACTER_TEXTURE_SIZE :: 350.0
CHARACTER_MOVEMENT_INTERVAL :: 0.20
ENEMY_MOVEMENT_INTERVAL :: 0.40
CHARACTER_POSE_INTERVAL :: 0.20
ENEMY_POSE_INTERVAL :: 0.10
ENEMY_TEXTURE_SIZE :: 256.0
NEW_HIGH_SCORES_TEXT :: "{\n\t\"easy\":\t0,\n\t\"medium\":\t0, \n\t\"hard\":\t0\n}"
NEW_MAP_TEXT :: "OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO\nOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO\nOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO\nOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO\nOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO\nOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO\nOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO\nOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO\nOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO\nOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO\nOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO\nOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO\nOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO\nOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO\nOOOOOOOOOOOOOOOO{--------T----}OOOOOOOOOOOOOOOOO\nOOOOOOOOOOOOOOOO|OOOOOOOO|OOOO|OOOOOOOOOOOOOOOOO\nOOOOOOOOOOOOOOOO|OOOOOOOO|OOOO|OOOOOOOOOOOOOOOOO\nOOOOOOOOOOOOOOOO|OOOOOOOO|OOOO|OOOOOOOOOOOOOOOOO\nOOOOOOOOOOOOOOOO|OOOOOOOO|OOOO|OOOOOOOOOOOOOOOOO\nOOOOOOOOOOOOOOOOL----T---Z----Z-T---}OOOOOOOOOOO\nOOOOOOOOOOOOOOOO|OOOO|OOOOOOOOOO|OOO|OOOOOOOOOOO\nOOOOOOOOOOOOOOOO|OOOO|OOOOOOOOOO|OOO|OOOOOOOOOOO\nOOOOOOOOOOOOOOOO|OOOO|OOOOOOOOOO|OOO|OOOOOOOOOOO\nOOOOOOOOOOOOOOOO|OOOO|OOOOOOOOOO|OOO|OOOOOOOOOOO\nOOOOOOOOOOOOOOOOL----Z---T---T--Z---JOOOOOOOOOOO\nOOOOOOOOOOOOOOOO|OOOOOOOO|OOO|OOOOOO|OOOOOOOOOOO\nOOOOOOOOOOOOOOOO|OOOOOOOO|OOO|OOOOOO|OOOOOOOOOOO\nOOOOOOOOOOOOOOOO|OOOOOOOO|OOOLOOOOOOL----}OOOOOO\nOOOOOOOOOOOOOOOO|OOOOOOOO|OOO|OOOOOO|OOOO|OOOOOO\nOOOOOOOOOOOOOOOO|OOOOOOOO|OOOL------JOOOO|OOOOOO\nOOOOOOOOOOOOOOOOL----T---Z---JOOOOOO|O{--]OOOOOO\nOOOOOOOOOOOOOOOO|OOOO|OOOOOOO|OOOOOO|O|OOOOOOOOO\nOOOOOOOOOOOOOOOO|OOOO|OOOOOOO|OOOOOO|O|OOOOOOOOO\nOOOOOOOOOOOOOOOO|OOOO|OOOOOOO|OOOOOOL-]OOOOOOOOO\nOOOOOOOOOOOOOOOO|OOOO|OOOOOOO|OOOOOO|OOOOOOOOOOO\nOOOOOOOOOOOOOOOO[----Z-------Z------]OOOOOOOOOOO\nOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO\nOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO\nOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO\nOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO\nOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO\nOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO\nOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO\nOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO\nOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO\nOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO\nOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO"
