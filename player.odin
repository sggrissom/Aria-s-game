package main

import "core:fmt"
import "core:math"
import "core:math/linalg"
import "core:math/rand"
import "core:strings"
import "core:time"
import rl "vendor:raylib"

try_pick_up_entity :: proc(player: ^Entity) {
    for key in player.entity_ids {
        item := entity_get(key)
		if .Cart in item.flags {
			player.holding.item = item
			if .Cart in item.flags {
				player.holding.offset_map = make(map[Direction]Vec2)
				player.holding.offset_map[.UP] = Vec2{-14, -22}
				player.holding.offset_map[.DOWN] = Vec2{-12, 22}
				player.holding.offset_map[.LEFT] = Vec2{-60, -5}
				player.holding.offset_map[.RIGHT] = Vec2{42, -5}
			}
			break
		}
    }
}

drop_entity :: proc(player: ^Entity) {
    delete(player.holding.offset_map)
    player.holding.flags -= {.In_Motion}
	update_animation(player.holding.item)
    player.holding.item = nil
}

held_item_update :: proc(player: ^Entity) {
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
        player.holding.combined_collider.y += 10

	player.holding.flags -= { .In_Motion }
	if .In_Motion in player.flags {
		player.holding.flags += { .In_Motion }
	}
}

player_update :: proc(dt: f32) {
	player := entity_get(gs.player_id)
	player.input = {}
	player.flags -= { .In_Motion }

	player.combined_collider = player.collider

	if rl.IsKeyDown(.W) || rl.IsKeyDown(.UP) do player.input.y = -1
	if rl.IsKeyDown(.S) || rl.IsKeyDown(.DOWN) do player.input.y = 1
	if rl.IsKeyDown(.A) || rl.IsKeyDown(.LEFT) do player.input.x = -1
	if rl.IsKeyDown(.D) || rl.IsKeyDown(.RIGHT) do player.input.x = 1
	if rl.IsKeyPressed(rl.KeyboardKey.SPACE) {
		if player.holding.item == nil {
            try_pick_up_entity(player)
		} else {
            drop_entity(player)
		}
	}

	isMoving := player.input != {0, 0}
	if isMoving {
		player.flags += { .In_Motion }
	}
	isHolding := player.holding.item != nil

	switch player.state {
		case .STILL:
			if isMoving do player.state = .WALK
			if isHolding do player.state = .HOLD
		case .WALK:
			if !isMoving do player.state = .STILL
			if isHolding do player.state = .HOLD
		case .HOLD:
			if !isHolding && isMoving do player.state = .WALK
			if !isHolding && !isMoving do player.state = .STILL
		case .EMPTY:
		case .FULL:
	}

	prevDirection := player.direction
	if player.input.x == 1 do player.direction = .RIGHT
	if player.input.x == -1 do player.direction = .LEFT
	if player.input.y == 1 do player.direction = .DOWN
	if player.input.y == -1 do player.direction = .UP
	directionChanged := player.direction != prevDirection

	if (isHolding) {
        held_item_update(player)
        combine_rects(player)
		if directionChanged && !can_direction_change(player, gs.colliders[:], dt) {
			player.direction = prevDirection
			directionChanged = false
			held_item_update(player)
			combine_rects(player)
		}
	}

	gs.cam.target = {player.x - player.width / 2, player.y - player.height / 2}

	update_animation(player)
	if isHolding {
		update_animation(player.holding.item)
	}
}

update_animation :: proc (entity: ^Entity) {
	stateName := get_state_animation_name(entity)
	directionName := get_direction_animation_name(entity)
	builder := new(strings.Builder, context.temp_allocator)
	animationName := fmt.sbprintf(builder, "%s-%s", stateName, directionName)
	if animationName != entity.current_anim_name do switch_animation(entity, animationName)
}

get_direction_animation_name :: proc (entity: ^Entity) -> string {
	switch entity.direction {
		case .LEFT:
			return "left"
		case .RIGHT:
			return "right"
		case .UP:
			return "up"
		case .DOWN:
			return "down"
	}
	return ""
}

get_state_animation_name :: proc (entity: ^Entity) -> string {
	inMotion := .In_Motion in entity.flags
	switch entity.state {
		case .STILL:
			return "idle"
		case .WALK:
			return "walk"
		case .HOLD:
			if !inMotion {
				return "push-idle"
			}
			return "push"
		case .EMPTY:
			if !inMotion {
				return "empty-idle"
			}
			return "empty"
		case .FULL:
			if !inMotion {
				return "empty-idle"
			}
			return "full"
	}
	return ""
}

combine_rects :: proc(entity: ^Entity) {
	if entity.holding.item == nil {
		return
	}

	checkRect := entity.collider
	checkRect.x += entity.x
	checkRect.y += entity.y

	heldRect := get_static_collider(entity.holding.item^)

	//debug_draw_rect(heldRect, 1, rl.GREEN)

	new_x := math.min(checkRect.x, heldRect.x)
	new_y := math.min(checkRect.y, heldRect.y)

	new_width := math.max(checkRect.x + checkRect.width, heldRect.x + heldRect.width) - new_x
	new_height := math.max(checkRect.y + checkRect.height, heldRect.y + heldRect.height) - new_y

	entity.combined_collider.x = new_x - entity.x
	entity.combined_collider.y = new_y - entity.y
	entity.combined_collider.width = new_width
	entity.combined_collider.height = new_height
}
