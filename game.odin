package main

import "core:fmt"
import "core:math"
import "core:math/linalg"
import "core:math/rand"
import rl "vendor:raylib"

Vec2 :: rl.Vector2
Rect :: rl.Rectangle

Direction :: enum {UP, DOWN, LEFT, RIGHT}
Scene :: enum {MENU, GAME}

WINDOW_WIDTH :: 1280
WINDOW_HEIGHT :: 720
ZOOM :: 2
BG_COLOR :: rl.BLACK

Game_State :: struct {
    window_size: Vec2,
    cart_id: int,
    food: Entity,
    cam: rl.Camera2D,
    entities: [dynamic]Entity,
    solid_tiles: [dynamic] Rect,
}

Entity :: struct {
    using collider: Rect,
    velocity: Vec2,
    move_speed: f32,
    animation: ^Animation,
    is_animating: bool,
    is_removed: bool,
    direction: Direction,
    is_empty: bool,
}

Sprite_Sheet :: struct {
    texture: rl.Texture2D,
    sheet_size: Vec2,
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

game_logic :: proc() {
    cart := entity_get(gs.cart_id)
    cart.velocity = {}
    if rl.IsKeyDown(rl.KeyboardKey.UP) {
        cart.velocity.y = -cart.move_speed
        cart.direction = .UP
    }
    if rl.IsKeyDown(rl.KeyboardKey.DOWN) {
        cart.velocity.y = cart.move_speed
        cart.direction = .DOWN
    }
    if rl.IsKeyDown(rl.KeyboardKey.LEFT) {
        cart.velocity.x = -cart.move_speed
        cart.direction = .LEFT
    }
    if rl.IsKeyDown(rl.KeyboardKey.RIGHT) {
        cart.velocity.x = cart.move_speed
        cart.direction = .RIGHT
    }
    if rl.IsKeyDown(rl.KeyboardKey.SPACE) {
        cart.is_empty = false
    } else {
        cart.is_empty = true
    }

    dt := rl.GetFrameTime()
    physics_update(gs.entities[:], gs.solid_tiles[:], dt)
    
    gs.cam.target = { cart.x - cart.width / 2, cart.y - cart.height / 2};
    cart.is_animating = cart.velocity != 0
}

PHYSICS_ITERATIONS :: 8

physics_update :: proc(entities: []Entity, static_colliders: []Rect, dt: f32)
{
    for &entity in entities {
        if entity.is_removed do continue

        for _ in 0 ..< PHYSICS_ITERATIONS {
            step := dt / PHYSICS_ITERATIONS

            entity.y += entity.velocity.y * step
            for static in static_colliders {
                if rl.CheckCollisionRecs(entity.collider, static) {
                    if entity.velocity.y > 0 {
                        entity.y = static.y - entity.height
                    } else {
                        entity.y = static.y + static.height
                    }
                    entity.velocity.y = 0
                    break
                }
            }
            entity.x += entity.velocity.x * step
            for static in static_colliders {
                if rl.CheckCollisionRecs(entity.collider, static) {
                    if entity.velocity.x > 0 {
                        entity.x = static.x - entity.width
                    } else {
                        entity.x = static.x + static.width
                    }
                    entity.velocity.x = 0
                    break
                }
            }
        }
    }
}

main :: proc() {
    gs = Game_State {
        window_size = {1280, 720}
    }
    gs.food = Entity {
        collider = {width = 50, height = 50, x = 50, y = 50},
        is_animating = true,
    }
    gs.cart_id = entity_create( {
        collider = {x = 100, y = 100, width = tileWidth, height = tileWidth,},
        direction = Direction.RIGHT,
        is_animating = false,
        move_speed = 300,
    })
    gs.cam = {
        offset = { gs.window_size.x / 2, gs.window_size.y / 2},
        zoom = ZOOM
    }

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

    read_map("resources/wall.map")

    gs.food.animation = &Animation {
        sprite_sheet = &food_sheet,
        frames = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10},
        frames_per_second = 3,
    }

    CART_FRAMES :: 3

    empty_left_cart = Animation {
        sprite_sheet = &cart_sheet,
        frames = {3, 4, 5},
        frames_per_second = CART_FRAMES,
    }
    empty_right_cart = Animation {
        sprite_sheet = &cart_sheet,
        frames = {6, 7, 8},
        frames_per_second = CART_FRAMES,
    }
    empty_up_cart = Animation {
        sprite_sheet = &cart_sheet,
        frames = {9, 10, 11},
        frames_per_second = CART_FRAMES,
    }
    empty_down_cart = Animation {
        sprite_sheet = &cart_sheet,
        frames = {0, 1, 2},
        frames_per_second = CART_FRAMES,
    }
    full_left_cart = Animation {
        sprite_sheet = &cart_sheet,
        frames = {3+12, 4+12, 5+12},
        frames_per_second = CART_FRAMES,
    }
    full_right_cart = Animation {
        sprite_sheet = &cart_sheet,
        frames = {6+12, 7+12, 8+12},
        frames_per_second = CART_FRAMES,
    }
    full_up_cart = Animation {
        sprite_sheet = &cart_sheet,
        frames = {9+12, 10+12, 11+12},
        frames_per_second = CART_FRAMES,
    }
    full_down_cart = Animation {
        sprite_sheet = &cart_sheet,
        frames = {0+12, 1+12, 2+12},
        frames_per_second = CART_FRAMES,
    }

    for !rl.WindowShouldClose() {
        game_logic()
        render_frame()
    }
}
