package main

import "core:strconv"
import "core:strings"
import "core:os"
import "core:math"
import "core:time"
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
    for &entity, e_id in entities {
        entity_id := Entity_Id(e_id)
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

        //debug_draw_rect(get_static_collider(entity), 1, rl.RED)

        for &other, o_id in entities {
			other_id := Entity_Id(o_id)
			if entity_id == other_id do continue

			if rl.CheckCollisionRecs(get_static_collider(entity), get_static_collider(other)) {
				if entity_id not_in other.entity_ids {
					other.entity_ids[entity_id] = time.now()

					if other.on_enter != nil {
						other.on_enter(other_id, entity_id)
					}
				} else {
					if other.on_stay != nil {
						other.on_stay(other_id, entity_id)
					}
				}
			} else if entity_id in other.entity_ids {
				if other.on_exit != nil {
					other.on_exit(other_id, entity_id)
				}
				delete_key(&other.entity_ids, entity_id)
			}
		}

    }
}