package main

import "core:fmt"
import "core:os"
import "core:math"
import "core:math/linalg"
import "core:math/rand"
import "core:strings"
import "core:strconv"
import rl "vendor:raylib"

read_map :: proc(filepath: string) -> Map {
	data, ok := os.read_entire_file(filepath, context.allocator)
    assert(ok, "error reading file")
	defer delete(data, context.allocator)

    file_contents := string(data)
    file_tokens := strings.fields(file_contents)
    map_width, _ := strconv.parse_int(file_tokens[0])
    map_height, _ := strconv.parse_int(file_tokens[1])

    numbers: [dynamic]i32 = {} 
    numberSourceMap : [dynamic]^Sprite_Sheet = {}

    tile_count :int = int(map_width * map_height)
    for token in file_tokens[2:] {
        val, ok := strconv.parse_int(token)
        if (ok) {
            append(&numbers, i32(val))
        } else {
            append(&numberSourceMap, &food_sheet)
        }
    }
    
    game_map: Map
    game_map.width = i32(map_width)
    game_map.height = i32(map_height)
    game_map.tiles = numbers
    game_map.tile_texture = numberSourceMap

    return game_map
}

game_logic :: proc() {
    is_moving := false
    if rl.IsKeyDown(rl.KeyboardKey.UP) {
        gs.cart.entity.position.y -= gs.cart.speed
        gs.cart.entity.direction = .UP
        is_moving = true
    }
    if rl.IsKeyDown(rl.KeyboardKey.DOWN) {
        gs.cart.entity.position.y += gs.cart.speed
        gs.cart.entity.direction = .DOWN
        is_moving = true
    }
    if rl.IsKeyDown(rl.KeyboardKey.LEFT) {
        gs.cart.entity.position.x -= gs.cart.speed
        gs.cart.entity.direction = .LEFT
        is_moving = true
    }
    if rl.IsKeyDown(rl.KeyboardKey.RIGHT) {
        gs.cart.entity.position.x += gs.cart.speed
        gs.cart.entity.direction = .RIGHT
        is_moving = true
    }
    if rl.IsKeyDown(rl.KeyboardKey.SPACE) {
        gs.cart.is_empty = false
    } else {
        gs.cart.is_empty = true
    }
    gs.cart.entity.position.x = linalg.clamp(gs.cart.entity.position.x, 0, gs.window_size.x - gs.cart.entity.position.width)
    gs.cart.entity.position.y = linalg.clamp(gs.cart.entity.position.y, 0, gs.window_size.y - gs.cart.entity.position.height)

    gs.cart.entity.is_animating = is_moving
}

main :: proc() {
    gs = Game_State {
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

    food_sheet = Sprite_Sheet {
        texture = rl.LoadTexture("resources/FOOD.png"),
        sheet_size = {64, 1632},
        sprite_rows = 51,
        sprite_columns = 2,
    }
    cart_sheet = Sprite_Sheet {
        texture = rl.LoadTexture("resources/CART.png"),
        sheet_size = {288, 768},
        sprite_rows = 8,
        sprite_columns = 3,
    }

    game_map = read_map("resources/world.map")

    gs.food.animation = &Animation {
        sprite_sheet = food_sheet,
        frames = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10},
        frames_per_second = 1,
    }

    empty_left_cart = Animation {
        sprite_sheet = cart_sheet,
        frames = {3, 4, 5},
        frames_per_second = 5,
    }
    empty_right_cart = Animation {
        sprite_sheet = cart_sheet,
        frames = {6, 7, 8},
        frames_per_second = 5,
    }
    empty_up_cart = Animation {
        sprite_sheet = cart_sheet,
        frames = {9, 10, 11},
        frames_per_second = 5,
    }
    empty_down_cart = Animation {
        sprite_sheet = cart_sheet,
        frames = {0, 1, 2},
        frames_per_second = 5,
    }
    full_left_cart = Animation {
        sprite_sheet = cart_sheet,
        frames = {3+12, 4+12, 5+12},
        frames_per_second = 5,
    }
    full_right_cart = Animation {
        sprite_sheet = cart_sheet,
        frames = {6+12, 7+12, 8+12},
        frames_per_second = 5,
    }
    full_up_cart = Animation {
        sprite_sheet = cart_sheet,
        frames = {9+12, 10+12, 11+12},
        frames_per_second = 5,
    }
    full_down_cart = Animation {
        sprite_sheet = cart_sheet,
        frames = {0+12, 1+12, 2+12},
        frames_per_second = 5,
    }

    for !rl.WindowShouldClose() {
        game_logic()
        render_frame()
    }
}
