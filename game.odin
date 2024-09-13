package main

import "core:fmt"
import "core:math"
import "core:math/linalg"
import "core:math/rand"
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
}

WINDOW_WIDTH :: 1280
WINDOW_HEIGHT :: 720
ZOOM :: 2
BG_COLOR :: rl.GRAY

colliderWidth :: 20
colliderHeight :: 10
playerHeight :: 48
playerWidth :: 33

Game_State :: struct {
	window_size:  Vec2,
	cart_id:      Entity_Id,
	player_id:    Entity_Id,
	cam:          rl.Camera2D,
	entities:     [dynamic]Entity,
	solid_tiles:  [dynamic]Entity,
	debug_shapes: [dynamic]Debug_Shape,
}

Entity :: struct {
	collider:          Rect,
	combined_collider: Rect,
	using position:    Rect,
	input:             Vec2,
	move_speed:        f32,
	animation:         ^Animation,
	state:             EntityState,
	direction:         Direction,
	holding:           HeldEntity,
	flags:             bit_set[Entity_Flags],
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

Map :: struct {
	width:  int,
	height: int,
	tiles:  [dynamic]^Entity,
}

game_logic :: proc() {
	player := entity_get(gs.player_id)
	player.input = {}
	player.state = .STILL
	player.flags -= {.In_Motion}

	cart := entity_get(gs.cart_id)
	cart.input = {}
	cart.state = .EMPTY
	cart.flags -= {.In_Motion}

	player.combined_collider = player.collider

	if rl.IsKeyDown(.W) || rl.IsKeyDown(.UP) {
		player.input.y = -1
		player.direction = .UP
		player.state = .WALK
		player.flags += {.In_Motion}
	}
	if rl.IsKeyDown(.S) || rl.IsKeyDown(.DOWN) {
		player.input.y = 1
		player.direction = .DOWN
		player.state = .WALK
		player.flags += {.In_Motion}
	}
	if rl.IsKeyDown(.A) || rl.IsKeyDown(.LEFT) {
		player.input.x = -1
		player.direction = .LEFT
		player.state = .WALK
		player.flags += {.In_Motion}
	}
	if rl.IsKeyDown(.D) || rl.IsKeyDown(.RIGHT) {
		player.input.x = 1
		player.direction = .RIGHT
		player.state = .WALK
		player.flags += {.In_Motion}
	}
	if rl.IsKeyPressed(rl.KeyboardKey.SPACE) {
		if (player.holding.item == nil) {
			cart.flags += {.Removed}
			if .In_Motion in player.flags {
				cart.flags += {.In_Motion}
			}
			player.holding.item = cart
			player.holding.offset_map = make(map[Direction]Vec2)
			player.holding.offset_map[.UP] = Vec2{-8, -CART_OFFSET}
			player.holding.offset_map[.DOWN] = Vec2{-9, CART_OFFSET}
			player.holding.offset_map[.LEFT] = Vec2{-(CART_OFFSET + 14), 5}
			player.holding.offset_map[.RIGHT] = Vec2{CART_OFFSET, 5}
		} else {
			delete(player.holding.offset_map)
			player.holding.flags -= {.Removed}
			player.holding.item = nil
		}
	}


	dt := rl.GetFrameTime()
	
	if (player.holding.item != nil) {
		player.state = .HOLD
		player.holding.x = player.x
		player.holding.y = player.y
		player.holding.direction = player.direction
		player.holding.x += player.holding.offset_map[player.direction].x
		player.holding.y += player.holding.offset_map[player.direction].y
		switch player.holding.direction {
		case .UP:
			player.holding.collider = {
				x      = (tileWidth - colliderWidth) / 2,
				y      = 0,
				width  = colliderWidth,
				height = colliderHeight,
			}
			break
		case .DOWN:
			player.holding.collider = {
				x      = (tileWidth - colliderWidth) / 2,
				y      = tileWidth - colliderHeight,
				width  = colliderWidth,
				height = colliderHeight,
			}
			break
		case .LEFT:
			player.holding.collider = {
				x      = 0,
				y      = (tileWidth - colliderWidth) / 2,
				width  = colliderHeight,
				height = colliderWidth,
			}
			break
		case .RIGHT:
			player.holding.collider = {
				x      = tileWidth - colliderHeight,
				y      = (tileWidth - colliderWidth) / 2,
				width  = colliderHeight,
				height = colliderWidth,
			}
			break
		}
		player.holding.combined_collider = player.holding.collider
	}

	player.combined_collider = player.collider
	combine_rects(player)
	physics_update(gs.entities[:], gs.solid_tiles[:], dt)

	CART_OFFSET :: 22
	if (player.holding.item != nil) {
		player.state = .HOLD
		player.holding.x = player.x
		player.holding.y = player.y
		player.holding.direction = player.direction
		player.holding.x += player.holding.offset_map[player.direction].x
		player.holding.y += player.holding.offset_map[player.direction].y
	}

	gs.cam.target = {player.x - player.width / 2, player.y - player.height / 2}
}

combine_rects :: proc(entity: ^Entity) {
	if entity.holding.item == nil {
		return
	}

	checkRect := entity.collider
	checkRect.x += entity.x
	checkRect.y += entity.y

	heldRect := get_static_collider(entity.holding.item^)

	new_x := math.min(checkRect.x, heldRect.x)
	new_y := math.min(checkRect.y, heldRect.y)

	new_width := math.max(checkRect.x + checkRect.width, heldRect.x + heldRect.width) - new_x
	new_height := math.max(checkRect.y + checkRect.height, heldRect.y + heldRect.height) - new_y

	entity.combined_collider.x = new_x - entity.x
	entity.combined_collider.y = new_y - entity.y
	entity.combined_collider.width = new_width
	entity.combined_collider.height = new_height
}

main :: proc() {
	gs = Game_State {
		window_size = {1280, 720},
	}
	gs.cart_id = entity_create(
		{
			position = {x = 100, y = 100, width = tileWidth, height = tileWidth},
			collider = {
				x = (tileWidth - colliderWidth) / 2,
				y = tileWidth - colliderHeight,
				width = colliderWidth,
				height = colliderHeight,
			},
			direction = Direction.RIGHT,
			move_speed = 200,
		},
	)
	gs.player_id = entity_create(
		{
			position = {x = 200, y = 200, width = playerWidth, height = playerHeight},
			collider = {
				x = (playerWidth - colliderWidth) / 2,
				y = playerHeight - colliderHeight,
				width = colliderWidth,
				height = colliderHeight,
			},
			direction = Direction.RIGHT,
			move_speed = 200,
		},
	)
	gs.cam = {
		offset = {gs.window_size.x / 2, gs.window_size.y / 2},
		zoom   = ZOOM,
	}

	rl.InitWindow(i32(gs.window_size.x), i32(gs.window_size.y), "hi ARiA!")
	rl.SetTargetFPS(60)

	food_sheet = Sprite_Sheet {
		texture        = rl.LoadTexture("resources/FOOD.png"),
		sheet_size     = {64, 1632},
		sprite_rows    = 51,
		sprite_columns = 2,
	}
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

	read_map("resources/wall.map")
	init_player_animations()

	for !rl.WindowShouldClose() {
		game_logic()
		render_frame()
	}
}
