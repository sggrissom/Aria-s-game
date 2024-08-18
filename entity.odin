package main

import rl "vendor:raylib"

Game_State :: struct {
    window_size: rl.Vector2,
    cart: Cart,
    food: Entity,
    cam: rl.Camera2D,
    entities: map[rl.Vector2][dynamic]^Entity,
}

Entity :: struct {
    position: rl.Rectangle,
    tile_coordinate: ^rl.Vector2,
    direction: Direction,
    animation: ^Animation,
    is_animating: bool,
}

Cart :: struct {
    entity: Entity,
    speed: f32,
    is_empty: bool,
}

Sprite_Sheet :: struct {
    texture: rl.Texture2D,
    sheet_size: rl.Vector2,
    sprite_rows: int,
    sprite_columns: int,
}

Animation :: struct {
    sprite_sheet: ^Sprite_Sheet,
    frames_per_second: int,
    frames: [dynamic]int, 
}

Map :: struct {
    width: int,
    height: int,
    tiles: [dynamic]^Entity,
}

Direction :: enum {UP, DOWN, LEFT, RIGHT}