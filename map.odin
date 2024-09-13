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
            tile.collider.x = 0
            tile.collider.y = 0
            tile.collider.width = tileWidth
            tile.collider.height = tileWidth
            tile.combined_collider = tile.collider
            tile.animation = get_wall_animation(frame)

            solid_tile_create(tile)
        }
    }
}

get_wall_animation :: proc(wall_frame : int) -> ^Animation {
    frame : int
    rotation : f32 = 0
    switch wall_frame {
        case 1: frame = 19 //top
        case 2: frame = 43 //bottom
        case 3: frame = 9  //top left corner
        case 4: frame = 14 //top right corner
        case 5: frame = 42 //bottom left corner
        case 6: frame = 45 //bottom right corner
        case 7: frame = 27 //bottom of top wall
        case 8: frame = 41 //left
        case 9: frame = 46 //right
        case 10: frame = 33 //int. top right
        case 11: frame = 38 //int. top left
        case 12: frame = 01 //right T
        case 13: frame = 06 //left T
        case 14: frame = 17 //right T2
        case 15: frame = 22 //left T2
        case 16: frame = 25 //left shadow wall
        case 17: frame = 31 //left shadow corner
        case 18: frame = 34 //int top left corner
        case 19: frame = 30 //right shadow wall
        case 20: frame = 29 //right shadow corner top
        case 21: frame = 37 //int top right corner
    }

    animation := new(Animation)
    animation.sprite_sheet = &walls_sheet
    frames := make([dynamic]int, 1, 1)
    frames[0] = frame
    animation.frames = frames

    return animation
}
