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
            x := tileWidth * f32(i % map_width)
            y := tileWidth * f32(i / map_width)

            append(&gs.solid_tiles, Rect{x, y, tileWidth, tileWidth})
        }
    }
}

