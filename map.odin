package main

import "core:strconv"
import "core:strings"
import "core:os"

read_map :: proc(filepath: string) {
	data, ok := os.read_entire_file(filepath, context.allocator)
    assert(ok, "error reading file")
	defer delete(data, context.allocator)

    file_contents := string(data)
    file_tokens := strings.fields(file_contents)
    map_width, _ := strconv.parse_int(file_tokens[0])
    map_height, _ := strconv.parse_int(file_tokens[1])

    tileWidth :: 48

    tile_count :int = int(map_width * map_height)

    entities := make([dynamic]^Entity, 0, tile_count)
    for token, i in file_tokens[2:] {
        frame, ok := strconv.parse_int(token)
        if (ok && frame > 0) {
            animation := new(Animation)
            animation.sprite_sheet = &walls_sheet
            frames := make([dynamic]int, 1, 1)
            frames[0] = frame
            animation.frames = frames

            tile := new(Entity)
            tile.position.width = tileWidth
            tile.position.height = tileWidth
            tile.position.x = tileWidth * f32(i % map_width)
            tile.position.y = tileWidth * f32(i / map_width)
            tile.is_animating = false
            tile.animation = animation
            append(&entities, tile)
            for wall in solid_walls {
                if (frame == wall) {
                    append(&(gs.colliding_entities), tile)
                }
            }

        }
    }
    
    game_map = new(Map)
    game_map.width = map_width
    game_map.height = map_height
    game_map.tiles = entities
}