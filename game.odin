package main

import "core:fmt"
import "core:math"
import "core:math/linalg"
import "core:math/rand"
import rl "vendor:raylib"

game_logic :: proc(using gs: ^Game_State) {
    is_moving := false
    if rl.IsKeyDown(rl.KeyboardKey.UP) {
        cart.entity.position.y -= cart.speed
        cart.entity.direction = .UP
        is_moving = true
    }
    if rl.IsKeyDown(rl.KeyboardKey.DOWN) {
        cart.entity.position.y += cart.speed
        cart.entity.direction = .DOWN
        is_moving = true
    }
    if rl.IsKeyDown(rl.KeyboardKey.LEFT) {
        cart.entity.position.x -= cart.speed
        cart.entity.direction = .LEFT
        is_moving = true
    }
    if rl.IsKeyDown(rl.KeyboardKey.RIGHT) {
        cart.entity.position.x += cart.speed
        cart.entity.direction = .RIGHT
        is_moving = true
    }
    if rl.IsKeyDown(rl.KeyboardKey.SPACE) {
        cart.is_empty = false
    } else {
        cart.is_empty = true
    }
    cart.entity.position.x = linalg.clamp(cart.entity.position.x, 0, window_size.x - cart.entity.position.width)
    cart.entity.position.y = linalg.clamp(cart.entity.position.y, 0, window_size.y - cart.entity.position.height)

    cart.entity.is_animating = is_moving
}

main :: proc() {
    gs := Game_State {
        window_size = {1280, 720},
    }
    gs.food = Entity {
        position = {width = 50, height = 50, x = 50, y = 50},
        is_animating = true,
    }
    gs.cart = Cart {
        entity = Entity {
            position = {x = gs.window_size.x / 2, y = gs.window_size.y / 2, width = 100, height=100,},
            direction = Direction.RIGHT,
            is_animating = false,
        },
        speed = 7,
        is_empty = true,
    }

    rl.InitWindow(i32(gs.window_size.x), i32(gs.window_size.y), "hi ARiA!")
    rl.SetTargetFPS(60)

    food_sheet := Sprite_Sheet {
        texture = rl.LoadTexture("resources/FOOD.png"),
        sheet_size = {64, 1632},
        sprite_rows = 51,
        sprite_columns = 2,
    }
    cart_sheet := Sprite_Sheet {
        texture = rl.LoadTexture("resources/CART.png"),
        sheet_size = {288, 768},
        sprite_rows = 8,
        sprite_columns = 3,
    }

    gs.food.animation = &Animation {
        sprite_sheet = food_sheet,
        frames = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10},
        frames_per_second = 1,
    }

    empty_left_cart := Animation {
        sprite_sheet = cart_sheet,
        frames = {3, 4, 5},
        frames_per_second = 5,
    }
    empty_right_cart := Animation {
        sprite_sheet = cart_sheet,
        frames = {6, 7, 8},
        frames_per_second = 5,
    }
    empty_up_cart := Animation {
        sprite_sheet = cart_sheet,
        frames = {9, 10, 11},
        frames_per_second = 5,
    }
    empty_down_cart := Animation {
        sprite_sheet = cart_sheet,
        frames = {0, 1, 2},
        frames_per_second = 5,
    }
    full_left_cart := Animation {
        sprite_sheet = cart_sheet,
        frames = {3+12, 4+12, 5+12},
        frames_per_second = 5,
    }
    full_right_cart := Animation {
        sprite_sheet = cart_sheet,
        frames = {6+12, 7+12, 8+12},
        frames_per_second = 5,
    }
    full_up_cart := Animation {
        sprite_sheet = cart_sheet,
        frames = {9+12, 10+12, 11+12},
        frames_per_second = 5,
    }
    full_down_cart := Animation {
        sprite_sheet = cart_sheet,
        frames = {0+12, 1+12, 2+12},
        frames_per_second = 5,
    }

    for !rl.WindowShouldClose() {

        game_logic(&gs)
        rl.BeginDrawing()
        rl.ClearBackground(rl.WHITE)
        render_entity(&gs.food)

        animation :^Animation

        if (gs.cart.entity.direction == Direction.UP) {
            gs.cart.entity.animation = gs.cart.is_empty ? &empty_up_cart : &full_up_cart
        }
        if (gs.cart.entity.direction == Direction.DOWN) {
            gs.cart.entity.animation = gs.cart.is_empty ? &empty_down_cart : &full_down_cart
        }
        if (gs.cart.entity.direction == Direction.LEFT) {
            gs.cart.entity.animation = gs.cart.is_empty ? &empty_left_cart : &full_left_cart
        }
        if (gs.cart.entity.direction == Direction.RIGHT) {
            gs.cart.entity.animation = gs.cart.is_empty ? &empty_right_cart : &full_right_cart
        }

        render_entity(&gs.cart.entity)
        rl.DrawFPS(10,10)
        rl.EndDrawing()
    }
}
