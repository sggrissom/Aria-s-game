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

    for token, i in file_tokens[2:] {
        frame, ok := strconv.parse_int(token)
        if (ok && frame > 0) {

            tile : Entity
            tile.width = tileWidth
            tile.height = tileWidth
            tile.x = tileWidth * f32(i % map_width)
            tile.y = tileWidth * f32(i / map_width)
            tile.is_animating = false
            tile.animation = get_wall_animation(frame)

            solid_tile_create(tile)
        }
    }
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
