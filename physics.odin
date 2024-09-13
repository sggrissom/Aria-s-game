package main

import "core:strconv"
import "core:strings"
import "core:os"
import "core:math"
import rl "vendor:raylib"

get_static_collider :: proc(entity: Entity) -> Rect {
    checkRect := entity.combined_collider
    checkRect.x += entity.x
    checkRect.y += entity.y
    return checkRect
}

PHYSICS_ITERATIONS :: 8

physics_update :: proc(entities: []Entity, static_colliders: []Entity, dt: f32)
{
    for &entity in entities {
        if .Removed in entity.flags do continue

        for _ in 0 ..< PHYSICS_ITERATIONS {
            step := dt / PHYSICS_ITERATIONS

            entity.y += entity.input.y * entity.move_speed * step
            for static in static_colliders {
                if rl.CheckCollisionRecs(get_static_collider(entity), get_static_collider(static)) {
                    if entity.input.y > 0 {
                        //DOWN
                        entity.y = static.y - entity.combined_collider.height - entity.combined_collider.y
                    } else {
                        //UP
                        entity.y = static.y + static.height - entity.combined_collider.y
                    }
                    entity.input.y = 0
                    break
                }
            }

            entity.x += entity.input.x * entity.move_speed * step
            for static in static_colliders {
                if rl.CheckCollisionRecs(get_static_collider(entity), get_static_collider(static)) {
                    if entity.input.x > 0 {
                        //RIGHT
                        entity.x = static.x - entity.combined_collider.width - entity.combined_collider.x
                    } else {
                        //LEFT
                        entity.x = static.x + static.width - entity.combined_collider.x
                    }
                    entity.input.x = 0
                    break
                }
            }
        }

        debug_draw_rect(entity.position, 1, rl.WHITE)
        debug_draw_rect(get_static_collider(entity), 1, rl.GREEN)
    }
}