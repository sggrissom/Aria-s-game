package main

import rl "vendor:raylib"

entity_create :: proc(entity: Entity) -> int {
    for &e, i in gs.entities {
        if e.is_removed {
            e = entity
            e.is_removed = false
            return i
        }
    }

    index := len(gs.entities)
    append(&gs.entities, entity)

    return index
}

entity_get :: proc(id: int) -> ^Entity {
    return &gs.entities[id]
}