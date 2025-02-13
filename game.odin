#+feature dynamic-literals
package main

import "core:time"
import rl "vendor:raylib"

Vec2 :: rl.Vector2
Rect :: rl.Rectangle
Entity_Id :: distinct int

Direction :: enum {
	UP,
	DOWN,
	LEFT,
	RIGHT,
}
Scene :: enum {
	MENU,
	GAME,
}
EntityState :: enum {
	STILL,
	WALK,
	HOLD,
	EMPTY,
	FULL,
}
Entity_Flags :: enum {
	Removed,
	Debug_Draw,
	In_Motion,
	Cart,
}

WINDOW_WIDTH :: 1280
WINDOW_HEIGHT :: 720
ZOOM :: 2
BG_COLOR :: rl.GRAY

colliderWidth :: 20
colliderHeight :: 20
playerHeight :: 48
playerWidth :: 33
CART_OFFSET :: 22

Game_State :: struct {
	window_size:  Vec2,
	player_id:    Entity_Id,
	cam:          rl.Camera2D,
	entities:     [dynamic]Entity,
	colliders:  [dynamic]Rect,
	tiles:     [dynamic]Tile,
	walls:     [dynamic]Tile,
	walls_fore:     [dynamic]Tile,
	debug_shapes: [dynamic]Debug_Shape,
	level_defintions:       map[string]Level,
	level:                  ^Level,
}

Entity :: struct {
	collider:                   Rect,
	combined_collider:          Rect,
	using position:             Rect,
	input:                      Vec2,
	move_speed:                 f32,
	animation:                  ^Animation,
	state:                      EntityState,
	direction:                  Direction,
	holding:                    HeldEntity,
	flags:                      bit_set[Entity_Flags],
	on_enter, on_stay, on_exit: proc(self_id, other_id: Entity_Id),
	entity_ids:                 map[Entity_Id]time.Time,
}

HeldEntity :: struct {
	using item: ^Entity,
	offset_map: map[Direction]Vec2,
}

Sprite_Sheet :: struct {
	texture:        rl.Texture2D,
	sheet_size:     Vec2,
	sprite_rows:    int,
	sprite_columns: int,
}

Animation :: struct {
	sprite_sheet:      ^Sprite_Sheet,
	frames_per_second: int,
	frames:            [dynamic]int,
}

Level :: struct {
	iid, name:    string,
	player_spawn: Maybe(Vec2),
	level_min:    Vec2,
	level_max:    Vec2,
	entities:     [dynamic]Entity,
	colliders:    [dynamic]Rect,
	tiles:        [dynamic]Tile,
	walls:        [dynamic]Tile,
	walls_fore:        [dynamic]Tile,
}

Tile :: struct {
	pos: Vec2,
	src: Vec2,
	f:   u8,
	tileset: string,
}

main :: proc() {
	gs = Game_State {
		window_size = {1280, 720},
	}
	gs.cam = {
		offset = {gs.window_size.x / 2, gs.window_size.y / 2},
		zoom   = ZOOM,
	}

	rl.InitWindow(i32(gs.window_size.x), i32(gs.window_size.y), "hi ARiA!")
	rl.SetTargetFPS(60)

	store_sheet = Sprite_Sheet {
		texture        = rl.LoadTexture("resources/STORE.png"),
		sheet_size     = {48, 80},
		sprite_rows    = 2,
		sprite_columns = 1,
	}
	walls_sheet = Sprite_Sheet {
		texture        = rl.LoadTexture("resources/WALLS-2.png"),
		sheet_size     = {384, 288},
		sprite_rows    = 6,
		sprite_columns = 8,
	}
	floor_sheet = Sprite_Sheet {
		texture        = rl.LoadTexture("resources/floors.png"),
		sheet_size     = {384, 288},
		sprite_rows    = 6,
		sprite_columns = 8,
	}
	cart_sheet = Sprite_Sheet {
		texture        = rl.LoadTexture("resources/CART.png"),
		sheet_size     = {288, 768},
		sprite_rows    = 8,
		sprite_columns = 3,
	}
	player_sheet = Sprite_Sheet {
		texture        = rl.LoadTexture("resources/char.png"),
		sheet_size     = {192, 70},
		sprite_rows    = 1,
		sprite_columns = 4,
	}
	player_walk_sheet = Sprite_Sheet {
		texture        = rl.LoadTexture("resources/char_walk.png"),
		sheet_size     = {1152, 78},
		sprite_rows    = 1,
		sprite_columns = 24,
	}
	player_push_sheet = Sprite_Sheet {
		texture        = rl.LoadTexture("resources/char_push.png"),
		sheet_size     = {1156, 80},
		sprite_rows    = 1,
		sprite_columns = 24,
	}

	read_map_ldtk("resources/game.ldtk")
	level_load(&gs.level_defintions["f8a3ba30-c210-11ef-a83b-c97012fb84fc"])
	init_player_animations()

	for !rl.WindowShouldClose() {
		dt := rl.GetFrameTime()

		player_update(dt)
		physics_update(gs.entities[:], gs.colliders[:], dt)
		render_frame()
	}
}
