package main

import rl "vendor:raylib"

entity_create :: proc(entity: Entity) -> Entity_Id {
    for &e, i in gs.entities {
        if .Removed in e.flags {
            e = entity
            e.flags -= {.Removed}
            return i
        }
    }

    index := len(gs.entities)
    append(&gs.entities, entity)

    return Entity_Id(index)
}

solid_tile_create :: proc(entity: Entity) {
    append(&gs.solid_tiles, entity)
}

entity_get :: proc(id: Entity_Id) -> ^Entity {
    if int(id) >= len(gs.entities) {
		return nil
	}
    return &gs.entities[int(id)]
}