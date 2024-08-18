package main

import "core:strconv"
import "core:strings"
import "core:os"
import rl "vendor:raylib"

tileWidth :: 48

read_map :: proc(filepath: string) {
	data, ok := os.read_entire_file(filepath, context.allocator)
    assert(ok, "error reading file")
	defer delete(data, context.allocator)

    file_contents := string(data)
    file_tokens := strings.fields(file_contents)
    map_width, _ := strconv.parse_int(file_tokens[0])
    map_height, _ := strconv.parse_int(file_tokens[1])

    tile_count :int = int(map_width * map_height)

    entities := make([dynamic]^Entity, 0, tile_count)
    for token, i in file_tokens[2:] {
        frame, ok := strconv.parse_int(token)
        if (ok && frame > 0) {
            tile := new(Entity)
            tile.position.width = tileWidth
            tile.position.height = tileWidth
            tile.position.x = tileWidth * f32(i % map_width)
            tile.position.y = tileWidth * f32(i / map_width)
            tile.tile_coordinate = get_coordiate(tile.position)
            tile.is_animating = false
            tile.animation = get_wall_animation(frame)
            append(&entities, tile)
            add_entity_to_coordinate(tile)
        }
    }
    
    game_map = new(Map)
    game_map.width = map_width
    game_map.height = map_height
    game_map.tiles = entities
}

get_wall_animation :: proc(wall_frame : int) -> ^Animation {
    frame : int
    rotation : f32 = 0
    switch wall_frame {
        case 1: frame = 20
        case 2: frame = 22
        case 3: frame = 43
        case 4: frame = 17
        case 5: frame = 09
        case 6: frame = 14
        case 7: frame = 45
        case 8: frame = 42
    }

    animation := new(Animation)
    animation.sprite_sheet = &walls_sheet
    frames := make([dynamic]int, 1, 1)
    frames[0] = frame
    animation.frames = frames

    return animation
}

get_coordiate :: proc (rect : rl.Rectangle) -> ^rl.Vector2 {
    coordinate := new(rl.Vector2)
    coordinate.x = f32(int((rect.x - (rect.width/2)) / tileWidth))
    coordinate.y = f32(int((rect.y - (rect.height/2)) / tileWidth))
    return coordinate
}

add_entity_to_coordinate :: proc(entity: ^Entity) {
    ok := entity.tile_coordinate^ in gs.entities
    if !ok {
        gs.entities[entity.tile_coordinate^] = make([dynamic]^Entity, 1, 1)
    }
    append(&(gs.entities[entity.tile_coordinate^]), entity)
}

is_coordinate_mapped :: proc(coordinate : rl.Vector2) -> bool {
    return coordinate in gs.entities
}