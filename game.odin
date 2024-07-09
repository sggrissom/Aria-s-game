package main

import "core:fmt"
import "core:math"
import "core:math/linalg"
import "core:math/rand"
import rl "vendor:raylib"

Game_State :: struct {
    window_size: rl.Vector2,
    character: Character,
    food: rl.Rectangle,
}

Character :: struct {
    position: rl.Rectangle,
    speed: f32,
    direction: Direction,
    is_moving: bool,
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

game_logic :: proc(using gs: ^Game_State) {
    is_moving := false
    if rl.IsKeyDown(rl.KeyboardKey.UP) {
        character.position.y -= character.speed
        character.direction = .UP
        is_moving = true
    }
    if rl.IsKeyDown(rl.KeyboardKey.DOWN) {
        character.position.y += character.speed
        character.direction = .DOWN
        is_moving = true
    }
    if rl.IsKeyDown(rl.KeyboardKey.LEFT) {
        character.position.x -= character.speed
        character.direction = .LEFT
        is_moving = true
    }
    if rl.IsKeyDown(rl.KeyboardKey.RIGHT) {
        character.position.x += character.speed
        character.direction = .RIGHT
        is_moving = true
    }
    character.position.x = linalg.clamp(character.position.x, 0, window_size.x - character.position.width)
    character.position.y = linalg.clamp(character.position.y, 0, window_size.y - character.position.height)

    character.is_moving = is_moving
}

render_game :: proc(using gs: ^Game_State) {
}

render_sprite :: proc(sprite_sheet: ^Sprite_Sheet, spriteToRender: i32, dest: rl.Rectangle)
{
    sprite_width :f32 = sprite_sheet.sheet_size.x / f32(sprite_sheet.sprite_columns);
    sprite_height :f32 = sprite_sheet.sheet_size.y / f32(sprite_sheet.sprite_rows);

    sprite_row : i32 = spriteToRender / sprite_sheet.sprite_columns
    sprite_column : i32 = spriteToRender % sprite_sheet.sprite_columns

    // Source rectangle (part of the texture to use for drawing)
    sourceRec : rl.Rectangle = { sprite_width * f32(sprite_column), (sprite_height * f32(sprite_row)), sprite_width, sprite_height };
    rl.DrawRectangleRec(dest, rl.DARKGREEN);
    rl.DrawTexturePro(sprite_sheet.texture, sourceRec, dest, {0, 0}, 0, rl.WHITE);
}

render_animation :: proc(animation: ^Animation, char: ^Character) {
    frameIndex : i32 = 0
    if (char.is_moving) {
        frameIndex = i32(rl.GetTime() * f64(animation.frames_per_second)) % i32(len(animation.frames))
    }
    render_sprite(&(animation.sprite_sheet), animation.frames[frameIndex], char.position)
}

main :: proc() {
    main_character := Character {
        position = {width = 64, height = 64},
        speed = 10,
        is_moving = false,
    }
    gs := Game_State {
        window_size = {1280, 720},
        food = {width = 50, height = 50, x = 50, y = 50},
        character = main_character,
    }

    using gs

    rl.InitWindow(i32(window_size.x), i32(window_size.y), "hi ARiA!")
    rl.SetTargetFPS(60)

    char_sheet := Sprite_Sheet {
        texture = rl.LoadTexture("resources/character_maleAdventurer_sheetHD.png"),
        sheet_size = {1728, 1280},
        sprite_rows = 5,
        sprite_columns = 9,
    }
    food_sheet := Sprite_Sheet {
        texture = rl.LoadTexture("resources/FOOD.png"),
        sheet_size = {64, 1632},
        sprite_rows = 51,
        sprite_columns = 2,
    }
    cart_sheet := Sprite_Sheet {
        texture = rl.LoadTexture("resources/CART.png"),
        sheet_size = {768, 768},
        sprite_rows = 12,
        sprite_columns = 12,
    }

    left_cart := Animation {
        sprite_sheet = cart_sheet,
        frames = {(12 * 3), (12 * 3) + 1, (12 * 3) + 2},
        frames_per_second = 5,
    }
    right_cart := Animation {
        sprite_sheet = cart_sheet,
        frames = {(0 * 3), (0 * 3) + 1, (0 * 3) + 2},
        frames_per_second = 5,
    }
    up_cart := Animation {
        sprite_sheet = cart_sheet,
        frames = {(10 * 4 * 3), (10 * 4 * 3) + 1, (10 * 4 * 3) + 2},
        frames_per_second = 5,
    }
    down_cart := Animation {
        sprite_sheet = cart_sheet,
        frames = {(7 * 4 * 3), (7 * 4 * 3) + 1, (7 * 4 * 3) + 2},
        frames_per_second = 5,
    }

    food_to_render : i32 = 0
    timer : i32 = 0

    for !rl.WindowShouldClose() {
        timer+=1
        if (timer % 20 == 0) {
            food_to_render += 1
            timer = 0
        }
        if (food_to_render > (food_sheet.sprite_rows * food_sheet.sprite_columns) - 1) {
            food_to_render = 0
        }

        game_logic(&gs)
        rl.BeginDrawing()
        rl.ClearBackground(rl.WHITE)
        render_sprite(&food_sheet, food_to_render, food)

        if (character.direction == Direction.UP) {
            render_animation(&up_cart, &character)
        }
        if (character.direction == Direction.DOWN) {
            render_animation(&down_cart, &character)
        }
        if (character.direction == Direction.LEFT) {
            render_animation(&left_cart, &character)
        }
        if (character.direction == Direction.RIGHT) {
            render_animation(&right_cart, &character)
        }
        rl.DrawFPS(10,10)
        rl.EndDrawing()
    }
}
