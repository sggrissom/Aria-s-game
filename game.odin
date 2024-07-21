package main

import "core:fmt"
import "core:math"
import "core:math/linalg"
import "core:math/rand"
import rl "vendor:raylib"

game_logic :: proc() {
    is_moving := false

    new_position := gs.cart.entity.position
    if rl.IsKeyDown(rl.KeyboardKey.UP) {
        new_position.y -= gs.cart.speed
        gs.cart.entity.direction = .UP
        is_moving = true
    }
    if rl.IsKeyDown(rl.KeyboardKey.DOWN) {
        new_position.y += gs.cart.speed
        gs.cart.entity.direction = .DOWN
        is_moving = true
    }
    if rl.IsKeyDown(rl.KeyboardKey.LEFT) {
        new_position.x -= gs.cart.speed
        gs.cart.entity.direction = .LEFT
        is_moving = true
    }
    if rl.IsKeyDown(rl.KeyboardKey.RIGHT) {
        new_position.x += gs.cart.speed
        gs.cart.entity.direction = .RIGHT
        is_moving = true
    }
    if rl.IsKeyDown(rl.KeyboardKey.SPACE) {
        gs.cart.is_empty = false
    } else {
        gs.cart.is_empty = true
    }
    new_position.x = linalg.clamp(new_position.x, 0, gs.window_size.x - new_position.width)
    new_position.y = linalg.clamp(new_position.y, 0, gs.window_size.y - new_position.height)

    if (!will_cart_collide(new_position)) {
        gs.cart.entity.position = new_position
        gs.cam.target = { gs.cart.entity.position.x - gs.cart.entity.position.width / 2, gs.cart.entity.position.y - gs.cart.entity.position.height / 2};
    }

    gs.cart.entity.is_animating = is_moving
}

will_cart_collide :: proc(test_position : rl.Rectangle) -> bool {
    test_coordinate := get_coordiate(test_position)
    defer free(test_coordinate)
    if is_coordinate_mapped(get_coordiate(test_position)^) {
        return false
    }
    return true
}

main :: proc() {
    gs = Game_State {
        window_size = {1280, 720}
    }
    gs.food = Entity {
        position = {width = 50, height = 50, x = 50, y = 50},
        is_animating = true,
    }
    gs.cart = Cart {
        entity = Entity {
            position = {x = gs.window_size.x / 2 - 200, y = gs.window_size.y / 2, width = tileWidth, height = tileWidth,},
            direction = Direction.RIGHT,
            is_animating = false,
        },
        speed = 7,
        is_empty = true,
    }
    gs.cam = {
        offset = { gs.window_size.x / 2, gs.window_size.y / 2},
        target = { gs.cart.entity.position.x - gs.cart.entity.position.width / 2, gs.cart.entity.position.y - gs.cart.entity.position.height / 2},
        rotation = 0,
        zoom = 1
    }
    gs.entities = make(map[rl.Vector2][dynamic]^Entity)

    rl.InitWindow(i32(gs.window_size.x), i32(gs.window_size.y), "hi ARiA!")
    rl.SetTargetFPS(60)

    food_sheet = Sprite_Sheet {
        texture = rl.LoadTexture("resources/FOOD.png"),
        sheet_size = {64, 1632},
        sprite_rows = 51,
        sprite_columns = 2,
    }
    store_sheet = Sprite_Sheet {
        texture = rl.LoadTexture("resources/STORE.png"),
        sheet_size = {48, 80},
        sprite_rows = 2,
        sprite_columns = 1,
    }
    walls_sheet = Sprite_Sheet {
        texture = rl.LoadTexture("resources/WALLS-2.png"),
        sheet_size = {384, 288},
        sprite_rows = 6,
        sprite_columns = 8,
    }
    cart_sheet = Sprite_Sheet {
        texture = rl.LoadTexture("resources/CART.png"),
        sheet_size = {288, 768},
        sprite_rows = 8,
        sprite_columns = 3,
    }

    read_map("resources/world.map")

    gs.food.animation = &Animation {
        sprite_sheet = &food_sheet,
        frames = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10},
        frames_per_second = 1,
    }

    empty_left_cart = Animation {
        sprite_sheet = &cart_sheet,
        frames = {3, 4, 5},
        frames_per_second = 5,
    }
    empty_right_cart = Animation {
        sprite_sheet = &cart_sheet,
        frames = {6, 7, 8},
        frames_per_second = 5,
    }
    empty_up_cart = Animation {
        sprite_sheet = &cart_sheet,
        frames = {9, 10, 11},
        frames_per_second = 5,
    }
    empty_down_cart = Animation {
        sprite_sheet = &cart_sheet,
        frames = {0, 1, 2},
        frames_per_second = 5,
    }
    full_left_cart = Animation {
        sprite_sheet = &cart_sheet,
        frames = {3+12, 4+12, 5+12},
        frames_per_second = 5,
    }
    full_right_cart = Animation {
        sprite_sheet = &cart_sheet,
        frames = {6+12, 7+12, 8+12},
        frames_per_second = 5,
    }
    full_up_cart = Animation {
        sprite_sheet = &cart_sheet,
        frames = {9+12, 10+12, 11+12},
        frames_per_second = 5,
    }
    full_down_cart = Animation {
        sprite_sheet = &cart_sheet,
        frames = {0+12, 1+12, 2+12},
        frames_per_second = 5,
    }

    for !rl.WindowShouldClose() {
        game_logic()
        render_frame()
    }
}
