package main

import rl "vendor:raylib"

Game_State :: struct {
    window_size: rl.Vector2,
    cart: Cart,
    food: Entity,
}

Entity :: struct {
    position: rl.Rectangle,
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
    sprite_rows: i32,
    sprite_columns: i32,
}

Animation :: struct {
    sprite_sheet: Sprite_Sheet,
    frames_per_second: i32,
    frames: []i32,
}

Direction :: enum {UP, DOWN, LEFT, RIGHT}