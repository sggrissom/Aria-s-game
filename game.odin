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
AnimationState :: enum {STILL, WALK, HOLDING}

WINDOW_WIDTH :: 1280
WINDOW_HEIGHT :: 720
ZOOM :: 2
BG_COLOR :: rl.GRAY

Game_State :: struct {
    window_size: Vec2,
    cart_id: int,
    player_id: int,
    food: Entity,
    cam: rl.Camera2D,
    entities: [dynamic]Entity,
    solid_tiles: [dynamic]Entity,
}

Entity :: struct {
    collider: Rect,
    using position: Rect,
    velocity: Vec2,
    move_speed: f32,
    animation: ^Animation,
    is_animating: bool,
    is_removed: bool,
    direction: Direction,
    is_empty: bool,
    holding: ^Entity,
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
    player := entity_get(gs.player_id)
    player.velocity = {}
    player.is_animating = false

    cart := entity_get(gs.cart_id)
    cart.velocity = {}
    cart.is_animating = false

    if rl.IsKeyDown(.W) || rl.IsKeyDown(.UP) {
        player.velocity.y = -cart.move_speed
        player.direction = .UP
        player.is_animating = true
    }
    if rl.IsKeyDown(.S) || rl.IsKeyDown(.DOWN) {
        player.velocity.y = cart.move_speed
        player.direction = .DOWN
        player.is_animating = true
    }
    if rl.IsKeyDown(.A) || rl.IsKeyDown(.LEFT) {
        player.velocity.x = -cart.move_speed
        player.direction = .LEFT
        player.is_animating = true
    }
    if rl.IsKeyDown(.D) || rl.IsKeyDown(.RIGHT) {
        player.velocity.x = cart.move_speed
        player.direction = .RIGHT
        player.is_animating = true
    }
    if rl.IsKeyDown(rl.KeyboardKey.SPACE) {
        cart.is_empty = false
        player.holding = cart
        cart.x = player.x
        cart.y = player.y
    } else {
        cart.is_empty = true
        player.holding = nil
    }

    dt := rl.GetFrameTime()
    physics_update(gs.entities[:], gs.solid_tiles[:], dt)
    
    gs.cam.target = { player.x - player.width / 2, player.y - player.height / 2};
}

main :: proc() {
    gs = Game_State {
        window_size = {1280, 720}
    }
    gs.food = Entity {
        position = {width = 50, height = 50, x = 50, y = 50},
        is_animating = true,
    }
    cartWidth :: 20
    cartHeight :: 10
    playerHeight :: 70
    gs.cart_id = entity_create( {
        position = {x = 100, y = 100, width = tileWidth, height = tileWidth,},
        collider = {x = (tileWidth - cartWidth)/2, y = tileWidth - cartHeight, width = cartWidth, height = cartHeight,},
        direction = Direction.RIGHT,
        is_animating = false,
        move_speed = 300,
    })
    gs.player_id = entity_create( {
        position = {x = 200, y = 200, width = tileWidth, height = playerHeight,},
        collider = {x = (tileWidth - cartWidth)/2, y = playerHeight - cartHeight, width = cartWidth, height = cartHeight,},
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
    player_sheet = Sprite_Sheet {
        texture = rl.LoadTexture("resources/char.png"),
        sheet_size = {192, 70},
        sprite_rows = 1,
        sprite_columns = 4,
    }
    player_walk_sheet = Sprite_Sheet {
        texture = rl.LoadTexture("resources/char_walk.png"),
        sheet_size = {1152, 78},
        sprite_rows = 1,
        sprite_columns = 24,
    }    
    player_push_sheet = Sprite_Sheet {
        texture = rl.LoadTexture("resources/char_push.png"),
        sheet_size = {1156, 80},
        sprite_rows = 1,
        sprite_columns = 24,
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
    player_up = Animation {
        sprite_sheet = &player_sheet,
        frames = {1},
        frames_per_second = CART_FRAMES,
    }
    player_down = Animation {
        sprite_sheet = &player_sheet,
        frames = {3},
        frames_per_second = CART_FRAMES,
    }
    player_left = Animation {
        sprite_sheet = &player_sheet,
        frames = {2},
        frames_per_second = CART_FRAMES,
    }
    player_right = Animation {
        sprite_sheet = &player_sheet,
        frames = {0},
        frames_per_second = CART_FRAMES,
    }
    player_up_walk = Animation {
        sprite_sheet = &player_walk_sheet,
        frames = {6,7,8,9,10,11},
        frames_per_second = 6,
    }
    player_down_walk = Animation {
        sprite_sheet = &player_walk_sheet,
        frames = {18,19,20,21,22,23},
        frames_per_second = 6,
    }
    player_left_walk = Animation {
        sprite_sheet = &player_walk_sheet,
        frames = {12,13,14,15,16,17},
        frames_per_second = 6,
    }
    player_right_walk = Animation {
        sprite_sheet = &player_walk_sheet,
        frames = {0,1,2,3,4,5},
        frames_per_second = 6,
    }
    player_up_push = Animation {
        sprite_sheet = &player_push_sheet,
        frames = {6,7,8,9,10,11},
        frames_per_second = 6,
    }
    player_down_push = Animation {
        sprite_sheet = &player_push_sheet,
        frames = {18,19,20,21,22,23},
        frames_per_second = 6,
    }
    player_left_push = Animation {
        sprite_sheet = &player_push_sheet,
        frames = {12,13,14,15,16,17},
        frames_per_second = 6,
    }
    player_right_push = Animation {
        sprite_sheet = &player_push_sheet,
        frames = {0,1,2,3,4,5},
        frames_per_second = 6,
    }

    for !rl.WindowShouldClose() {
        game_logic()
        render_frame()
    }
}
