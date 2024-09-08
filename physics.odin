package main

import "core:strconv"
import "core:strings"
import "core:os"
import "core:math"
import rl "vendor:raylib"

PHYSICS_ITERATIONS :: 8

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
        entity_collider := get_static_collider(entity)
        debug_draw_rect({entity_collider.x, entity_collider.y}, {entity_collider.width, entity_collider.height}, 1, rl.GREEN)

        for _ in 0 ..< PHYSICS_ITERATIONS {
            step := dt / PHYSICS_ITERATIONS

            entity.y += entity.velocity.y * step
            for static in static_colliders {
                if rl.CheckCollisionRecs(entity_collider, get_static_collider(static)) {
                    if entity.velocity.y > 0 {
                        entity.y = static.y - entity.height
                    } else {
                        entity.y = static.y + static.height - entity_collider.y
                    }
                    entity.velocity.y = 0
                    break
                }
            }

            entity.x += entity.velocity.x * step
            for static in static_colliders {
                if rl.CheckCollisionRecs(entity_collider, get_static_collider(static)) {
                    if entity.velocity.x > 0 {
                        entity.x = static.x - entity_collider.width - entity_collider.x
                    } else {
                        entity.x = static.x + static.width - entity_collider.x
                    }
                    entity.velocity.x = 0
                    break
                }
            }
        }
    }
}