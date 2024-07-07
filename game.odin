package main

import "core:fmt"
import "core:math"
import "core:math/linalg"
import "core:math/rand"
import rl "vendor:raylib"

Game_State :: struct {
    window_size: rl.Vector2,
    character: rl.Rectangle,
    food: rl.Rectangle,
    character_speed: f32,
}

Sprite_Sheet :: struct {
    texture: rl.Texture2D,
    sheet_size: rl.Vector2,
    sprite_rows: i32,
    sprite_columns: i32,
}

game_logic :: proc(using gs: ^Game_State) {
    if rl.IsKeyDown(rl.KeyboardKey.UP) {
        character.y -= character_speed
    }
    if rl.IsKeyDown(rl.KeyboardKey.DOWN) {
        character.y += character_speed
    }
    if rl.IsKeyDown(rl.KeyboardKey.LEFT) {
        character.x -= character_speed
    }
    if rl.IsKeyDown(rl.KeyboardKey.RIGHT) {
        character.x += character_speed
    }
    character.x = linalg.clamp(character.x, 0, window_size.x - character.width)
    character.y = linalg.clamp(character.y, 0, window_size.y - character.height)
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

main :: proc() {
    gs := Game_State {
        window_size = {1280, 720},
        character = {width = 64, height = 64},
        food = {width = 50, height = 50, x = 50, y = 50},
        character_speed = 10,
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

    food_to_render : i32 = 0
    sprite_to_render : i32 = 0
    timer : i32 = 0

    for !rl.WindowShouldClose() {
        timer+=1
        if (timer % 20 == 0) {
            sprite_to_render += 1
            food_to_render += 1
            timer = 0
        }
        if (sprite_to_render > (3) - 1) {
            sprite_to_render = 0
        }
        if (food_to_render > (food_sheet.sprite_rows * food_sheet.sprite_columns) - 1) {
            food_to_render = 0
        }

        game_logic(&gs)
        rl.BeginDrawing()
        rl.ClearBackground(rl.WHITE)
        //render_sprite(&char_sheet, sprite_to_render, character)
        render_sprite(&food_sheet, food_to_render, food)
        render_sprite(&cart_sheet, sprite_to_render + (3 * 12), character)
        rl.EndDrawing()
    }
}
