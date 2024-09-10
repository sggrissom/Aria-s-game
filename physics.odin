package main

import "core:strconv"
import "core:strings"
import "core:os"
import "core:math"
import rl "vendor:raylib"

get_static_collider :: proc(entity: Entity) -> Rect {
    checkRect := entity.collider
    checkRect.x += entity.x
    checkRect.y += entity.y
    if entity.holding.item != nil {
        heldRect := get_static_collider(entity.holding.item^)

        new_x := math.min(checkRect.x, heldRect.x)
        new_y := math.min(checkRect.y, heldRect.y)

        new_width := math.max(checkRect.x + checkRect.width, heldRect.x + heldRect.width) - new_x
        new_height := math.max(checkRect.y + checkRect.height, heldRect.y + heldRect.height) - new_y

        checkRect.x = new_x
        checkRect.y = new_y
        checkRect.width= new_width
        checkRect.height = new_height
    }
    return checkRect
}

physics_update :: proc(entities: []Entity, static_colliders: []Entity, dt: f32)
{
    for &entity in entities {
        if .Removed in entity.flags do continue

        entity.x += entity.input.x * entity.move_speed * dt
        entity.y += entity.input.y * entity.move_speed * dt

        entity_collider := get_static_collider(entity)

        resolved := entity_collider

        for static in static_colliders {
            normal : Vec2

            collision_rect := rl.GetCollisionRec(entity_collider, static)
            if collision_rect == {} do continue
            center_static := Vec2 {
                static.x + static.width / 2,
                static.y + static.height / 2,
            }
            center_moving := Vec2 {
                collision_rect.x + collision_rect.width / 2,
                collision_rect.y + collision_rect.height / 2,
            }
            dist := center_moving - center_static
            
            if abs(dist.x) > abs(dist.y) {
                normal.x = 1 if dist.x > 0 else -1
            } else {
                normal.y = 1 if dist.y > 0 else -1
            }

            if normal.x < 0 {
                //Left
                resolved.x = static.x - resolved.width
            } else if normal.x > 0 {
                //Right
                resolved.x = static.x + static.width
            } else if normal.y < 0 {
                //Up
                resolved.y = static.y - resolved.height
            } else if normal.y > 0 {
                //Down
                resolved.y = static.y + static.height
            }
        }

        debug_draw_rect({entity_collider.x, entity_collider.y}, {entity_collider.width, entity_collider.height}, 1, rl.GREEN)
        if resolved != {} {
            debug_draw_rect({resolved.x, resolved.y}, {resolved.width, resolved.height}, 1, rl.RED)
        }
    }
}