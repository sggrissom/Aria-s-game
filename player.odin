package main

import "core:fmt"
import "core:math"
import "core:math/linalg"
import "core:math/rand"
import "core:time"
import rl "vendor:raylib"

player_update :: proc(dt: f32) {
	player := entity_get(gs.player_id)
	player.input = {}
	player.state = .STILL
	player.flags -= {.In_Motion}

	player.combined_collider = player.collider

	currentDirection :=  player.direction
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
		if player.holding.item == nil {
			for key in player.entity_ids {
				item := entity_get(key)
				item.flags += {.Removed}
				if .In_Motion in player.flags {
					item.flags += {.In_Motion}
				}
				player.holding.item = item
				player.holding.offset_map = make(map[Direction]Vec2)
				player.holding.offset_map[.UP] = Vec2{-8, -CART_OFFSET}
				player.holding.offset_map[.DOWN] = Vec2{-9, CART_OFFSET}
				player.holding.offset_map[.LEFT] = Vec2{-(CART_OFFSET + 14), 5}
				player.holding.offset_map[.RIGHT] = Vec2{CART_OFFSET, 5}
				break
			}
		} else {
			delete(player.holding.offset_map)
			player.holding.flags -= {.Removed}
			player.holding.flags -= {.In_Motion}
			player.holding.item = nil
		}
	}

	if (player.holding.item != nil) {
		player.state = .HOLD
		player.holding.x = player.x
		player.holding.y = player.y
		player.holding.direction = player.direction
		player.holding.x += player.holding.offset_map[player.direction].x
		player.holding.y += player.holding.offset_map[player.direction].y
		switch player.holding.direction {
		case .UP:
		case .DOWN:
		   player.holding.collider.width = colliderWidth
		   player.holding.collider.height = colliderHeight
		case .LEFT:
		case .RIGHT:
		   player.holding.collider.width = colliderHeight
		   player.holding.collider.height = colliderWidth
		}
		player.holding.combined_collider = player.holding.collider
	}

	player.combined_collider = player.collider
	combine_rects(player)

	if (player.direction != currentDirection && !can_direction_change(player, gs.solid_tiles[:], dt)) {
		player.input = {}
		player.direction = currentDirection
		player.state = .STILL
		player.flags -= {.In_Motion}
		if (player.holding.item != nil) {
			player.state = .HOLD
			player.holding.direction = player.direction
			player.holding.x += player.holding.offset_map[player.direction].x
			player.holding.y += player.holding.offset_map[player.direction].y
			switch player.holding.direction {
			case .UP:
			case .DOWN:
			player.holding.collider.width = colliderWidth
			player.holding.collider.height = colliderHeight
			case .LEFT:
			case .RIGHT:
			player.holding.collider.width = colliderHeight
			player.holding.collider.height = colliderWidth
			}
			player.holding.combined_collider = player.holding.collider
			combine_rects(player)
		}
	}

	// if (player.holding.item != nil) {
	// 	player.state = .HOLD
	// 	player.holding.x = player.x
	// 	player.holding.y = player.y
	// 	player.holding.direction = player.direction
	// 	player.holding.x += player.holding.offset_map[player.direction].x
	// 	player.holding.y += player.holding.offset_map[player.direction].y
	// }

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

	debug_draw_rect(heldRect, 1, rl.GREEN)

	new_x := math.min(checkRect.x, heldRect.x)
	new_y := math.min(checkRect.y, heldRect.y)

	new_width := math.max(checkRect.x + checkRect.width, heldRect.x + heldRect.width) - new_x
	new_height := math.max(checkRect.y + checkRect.height, heldRect.y + heldRect.height) - new_y

	entity.combined_collider.x = new_x - entity.x
	entity.combined_collider.y = new_y - entity.y
	entity.combined_collider.width = new_width
	entity.combined_collider.height = new_height
}
