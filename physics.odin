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

get_resolved_rect :: proc(dist: Vec2, static: Entity, resolved: ^Rect) -> Rect
{
    normal : Vec2
    if abs(dist.x) > abs(dist.y) {
        normal.x = 1 if dist.x > 0 else -1
    } else {
        normal.y = 1 if dist.y > 0 else -1
    }

    if normal.x < 0 && !rl.CheckCollisionRecs({static.x - resolved.width, resolved.y, resolved.width, resolved.height}, static) {
        //Left
        resolved.x = static.x - resolved.width
    } else if normal.x > 0 && !rl.CheckCollisionRecs({static.x + static.width, resolved.y, resolved.width, resolved.height}, static) {
        //Right
        resolved.x = static.x + static.width
    } else if normal.y < 0 && !rl.CheckCollisionRecs({resolved.x, static.y - resolved.height, resolved.width, resolved.height}, static) {
        //Up
        resolved.y = static.y - resolved.height
    } else if normal.y > 0 && !rl.CheckCollisionRecs({resolved.x, static.y + static.height, resolved.width, resolved.height}, static) {
        //Down
        resolved.y = static.y + static.height
    }

    return resolved^
}

physics_update :: proc(entities: []Entity, static_colliders: []Entity, dt: f32)
{
    //physics_update_by_centers(entities, static_colliders, dt)
    physics_update_with_steps(entities, static_colliders, dt)
}

physics_update_by_centers :: proc(entities: []Entity, static_colliders: []Entity, dt: f32)
{
    for &entity in entities {
        if .Removed in entity.flags do continue

        entity.x += entity.input.x * entity.move_speed * dt
        entity.y += entity.input.y * entity.move_speed * dt

        entity_collider := get_static_collider(entity)

        for static in static_colliders {
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
            
            resolved := entity_collider
            resolved = get_resolved_rect(dist, static, &resolved)

            entity.x += resolved.x - entity_collider.x
            entity.y += resolved.y - entity_collider.y
            break
        }

        debug_draw_rect({entity_collider.x, entity_collider.y}, {entity_collider.width, entity_collider.height}, 1, rl.GREEN)
    }
}

PHYSICS_ITERATIONS :: 8

physics_update_with_steps :: proc(entities: []Entity, static_colliders: []Entity, dt: f32)
{
    for &entity in entities {
        if .Removed in entity.flags do continue

        for _ in 0 ..< PHYSICS_ITERATIONS {
            step := dt / PHYSICS_ITERATIONS

            entity.y += entity.input.y * entity.move_speed * step
            for static in static_colliders {
                if rl.CheckCollisionRecs(get_static_collider(entity), get_static_collider(static)) {
                    if entity.input.y > 0 {
                        entity.y = static.y - entity.height
                    } else {
                        entity.y = static.y + static.height - entity.collider.y
                    }
                    entity.input.y = 0
                    break
                }
            }

            entity.x += entity.input.x * entity.move_speed * step
            for static in static_colliders {
                if rl.CheckCollisionRecs(get_static_collider(entity), get_static_collider(static)) {
                    if entity.input.x > 0 {
                        entity.x = static.x - entity.width + entity.collider.x
                    } else {
                        entity.x = static.x + static.width - entity.collider.x
                    }
                    entity.input.x = 0
                    break
                }
            }
        }
    }
}