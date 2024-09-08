package main

import "core:strconv"
import "core:strings"
import "core:os"
import rl "vendor:raylib"

PHYSICS_ITERATIONS :: 8

get_static_collider :: proc(entity: Entity) -> Rect {
    checkRect := entity.collider
    checkRect.x += entity.x
    checkRect.y += entity.y
    return checkRect
}

physics_update :: proc(entities: []Entity, static_colliders: []Entity, dt: f32)
{
    for &entity in entities {
        if .Removed in entity.flags do continue

        for _ in 0 ..< PHYSICS_ITERATIONS {
            step := dt / PHYSICS_ITERATIONS

            entity.y += entity.velocity.y * step
            for static in static_colliders {
                if rl.CheckCollisionRecs(get_static_collider(entity), get_static_collider(static)) {
                    if entity.velocity.y > 0 {
                        entity.y = static.y - entity.height
                    } else {
                        entity.y = static.y + static.height - entity.collider.y
                    }
                    entity.velocity.y = 0
                    break
                }
                if entity.holding.item != nil && rl.CheckCollisionRecs(get_static_collider(entity.holding.item^), get_static_collider(static)) {
                    if entity.velocity.y > 0 {
                        entity.y = static.y - entity.height - entity.holding.offset_map[.DOWN].y - entity.holding.height
                    } else {
                        entity.y = static.y + static.height - entity.collider.y + entity.holding.offset_map[.UP].y + entity.holding.height
                    }
                    entity.velocity.y = 0
                    break
                }
            }

            entity.x += entity.velocity.x * step
            for static in static_colliders {
                if rl.CheckCollisionRecs(get_static_collider(entity), get_static_collider(static)) {
                    if entity.velocity.x > 0 {
                        entity.x = static.x - entity.width + entity.collider.x - entity.holding.offset_map[.RIGHT].x - entity.holding.width
                    } else {
                        entity.x = static.x + static.width - entity.collider.x + entity.holding.offset_map[.LEFT].x + entity.holding.width
                    }
                    entity.velocity.x = 0
                    break
                }
                if entity.holding.item != nil && rl.CheckCollisionRecs(get_static_collider(entity.holding.item^), get_static_collider(static)) {
                    if entity.velocity.x > 0 {
                        entity.x = static.x - entity.width + entity.collider.x
                    } else {
                        entity.x = static.x + static.width - entity.collider.x
                    }
                    entity.velocity.x = 0
                    break
                }
            }
        }
    }
}