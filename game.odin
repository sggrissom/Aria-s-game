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
EntityState :: enum {STILL, WALK, HOLD, EMPTY, FULL}

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
    state: EntityState,
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
    player.state = .STILL

    cart := entity_get(gs.cart_id)
    cart.velocity = {}
    cart.state = .EMPTY

    if rl.IsKeyDown(.W) || rl.IsKeyDown(.UP) {
        player.velocity.y = -cart.move_speed
        player.direction = .UP
        player.state = .WALK
    }
    if rl.IsKeyDown(.S) || rl.IsKeyDown(.DOWN) {
        player.velocity.y = cart.move_speed
        player.direction = .DOWN
        player.state = .WALK
    }
    if rl.IsKeyDown(.A) || rl.IsKeyDown(.LEFT) {
        player.velocity.x = -cart.move_speed
        player.direction = .LEFT
        player.state = .WALK
    }
    if rl.IsKeyDown(.D) || rl.IsKeyDown(.RIGHT) {
        player.velocity.x = cart.move_speed
        player.direction = .RIGHT
        player.state = .WALK
    }
    if rl.IsKeyPressed(rl.KeyboardKey.SPACE) {
        if (player.holding == nil) {
            cart.is_removed = true
            player.holding = cart
        } else {
            player.holding.is_removed = false
            player.holding = nil
        }
    }


    dt := rl.GetFrameTime()
    physics_update(gs.entities[:], gs.solid_tiles[:], dt)

    CART_OFFSET :: 22
    if (player.holding != nil) {
        player.state = .HOLD
        cart.x = player.x
        cart.y = player.y
        cart.direction = player.direction
        switch cart.direction {
            case .UP: 
            player.holding.y -= CART_OFFSET
            player.holding.x -= 8
            break
            case .DOWN: 
            player.holding.y += CART_OFFSET
            player.holding.x -= 9
            break
            case .LEFT: 
            player.holding.x -= CART_OFFSET + 14
            player.holding.y += 5
            break
            case .RIGHT: 
            player.holding.x += CART_OFFSET
            player.holding.y += 5
            break
        }
    }
    
    gs.cam.target = { player.x - player.width / 2, player.y - player.height / 2};
}

main :: proc() {
    gs = Game_State {
        window_size = {1280, 720}
    }
    gs.food = Entity {
        position = {width = 50, height = 50, x = 50, y = 50},
    }
    colliderWidth :: 20
    colliderHeight :: 10
    playerHeight :: 48
    playerWidth :: 33
    gs.cart_id = entity_create( {
        position = {x = 100, y = 100, width = tileWidth, height = tileWidth,},
        collider = {x = (tileWidth - colliderWidth)/2, y = tileWidth - colliderHeight, width = colliderWidth, height = colliderHeight,},
        direction = Direction.RIGHT,
        move_speed = 300,
    })
    gs.player_id = entity_create( {
        position = {x = 200, y = 200, width = playerWidth, height = playerHeight,},
        collider = {x = (playerWidth - colliderWidth)/2, y = playerHeight - colliderHeight, width = colliderWidth, height = colliderHeight,},
        direction = Direction.RIGHT,
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
    init_player_animations()

    for !rl.WindowShouldClose() {
        game_logic()
        render_frame()
    }
}
