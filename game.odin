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
	Shelf,
}

WINDOW_WIDTH :: 1280
WINDOW_HEIGHT :: 720
ZOOM :: 2
BG_COLOR :: rl.GRAY

colliderWidth :: 20
colliderHeight :: 20
playerHeight :: 48
playerWidth :: 33

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
	state:                      EntityState,
	direction:                  Direction,
	holding:                    HeldEntity,
	flags:                      bit_set[Entity_Flags],
	on_enter, on_stay, on_exit: proc(self_id, other_id: Entity_Id),
	entity_ids:                 map[Entity_Id]time.Time,
	texture:                    ^rl.Texture,
	animations:                 map[string]^Animation,
	current_anim_name:          string,
	current_anim_frame:         int,
	animation_timer:            f32,
}

HeldEntity :: struct {
	using item: ^Entity,
	offset_map: map[Direction]Vec2,
}

Animation :: struct {
	size:         Vec2,
	offset:       Vec2,
	start:        int,
	end:          int,
	row:          int,
	time:         f32,
	flags:        bit_set[Animation_Flags],
}

Animation_Flags :: enum {
	Loop,
	Ping_Pong,
}

Animation_Event :: struct {
	timer:    f32,
	duration: f32,
	callback: proc(gs: ^Game_State, entity: ^Entity),
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

	store_texture = rl.LoadTexture("resources/STORE.png")
	walls_texture = rl.LoadTexture("resources/WALLS-2.png")
	floor_texture = rl.LoadTexture("resources/floors.png")
	cart_texture = rl.LoadTexture("resources/carts.png")
	blue_char_texture = rl.LoadTexture("resources/blue-char.png")

	read_map_ldtk("resources/game.ldtk")
	level_load(&gs.level_defintions["f8a3ba30-c210-11ef-a83b-c97012fb84fc"])
	init_player_animations()

	for !rl.WindowShouldClose() {
		dt := rl.GetFrameTime()

		player_update(dt)
		physics_update(gs.entities[:], gs.colliders[:], dt)
		entity_update(dt)
		render_frame()
	}
}
