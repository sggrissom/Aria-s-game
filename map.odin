#+feature dynamic-literals
package main

import "core:encoding/json"
import "core:log"
import "core:os"
import "core:strconv"
import "core:strings"
import rl "vendor:raylib"

tileWidth :: 48

LDtk_Data :: struct {
	levels: []LDtk_Level,
}

LDtk_Level :: struct {
	identifier:     string,
	iid:            string,
	layerInstances: []LDtk_Layer_Instance,
	__neighbours:   []LDtk_Neighbor,
	worldX, worldY: f32,
	pxWid, pxHei:   f32,
}

LDtk_Neighbor :: struct {
	levelIid: string,
	dir:      string,
}

LDtk_Layer_Instance :: struct {
	__identifier: string,
	__type: string,
	__cWid, __cHei: int,
	__tilesetRelPath: string,
	intGridCsv: []int,
	autoLayerTiles: []LDtk_Auto_Layer_Tile,
	entityInstances: []LDtk_Entity,
}

LDtk_Auto_Layer_Tile :: struct {
	px: [2]f32,
	src: [2]f32,
	f:   u8,
}

LDtk_Entity :: struct {
	iid:            string,
	__identifier:   string,
	__worldX:       f32,
	__worldY:       f32,
	__tags:         []string,
	width, height:  f32,
	fieldInstances: []LDtk_Field_Instance,
}

LDtk_Field_Instance :: struct {
	__identifier: string,
	__type:       string,
	__value:      LDtk_Field_Instance_Value,
}

LDtk_Field_Instance_Value :: union {
	LDtk_Entity_Ref,
	bool,
	f32,
	int,
	string,
}

LDtk_Entity_Ref :: struct {
	entityIid, layerIid, levelIid, worldIid: string,
}

read_map_ldtk :: proc(filepath: string) {
	level_data, ok := os.read_entire_file(filepath, allocator = context.allocator)
	assert(ok, "Failed to load level data")

	ldtk_data := new(LDtk_Data, context.temp_allocator)
	err := json.unmarshal(level_data, ldtk_data, allocator = context.temp_allocator)
	if err != nil {
		log.panicf("failed to parse json: %v", err)
	}

	for &level in ldtk_data.levels {
		level_parse_and_store(&gs, &level)
	}

}

level_parse_and_store :: proc(gs: ^Game_State, level: ^LDtk_Level) {
	l: Level

	l.iid = strings.clone(level.iid)
	l.name = strings.clone(level.identifier)

	l.level_min = {level.worldX, level.worldY}
	l.level_max = l.level_min + {level.pxWid, level.pxHei}
	for layer in level.layerInstances {
		switch layer.__identifier {
		case "Entities":
			for entity in layer.entityInstances {
				switch entity.__identifier {
				case "Player":
					l.player_spawn = Vec2{entity.__worldX, entity.__worldY}
				case "Cart":
				}
			}
		case "Collision":
			solid_tiles := make([dynamic]Rect, context.temp_allocator)

			x, y: f32
			for v, i in layer.intGridCsv {
				if v != 0 {
					//append(&l.colliders, Rect{x, y, tileWidth, tileWidth})
				}
				x += tileWidth
				if (i + 1) % layer.__cWid == 0 {
					y += tileWidth
					x = 0
				}
			}

			// Tiles
			for auto_tile in layer.autoLayerTiles {
				append(&l.tiles, Tile{auto_tile.px + l.level_min, auto_tile.src, auto_tile.f, layer.__tilesetRelPath})
			}
		}
	}

	gs.level_defintions[l.iid] = l
}

level_load :: proc(level: ^Level) {
	gs.level = level

	clear(&gs.entities)
	clear(&gs.colliders)
	clear(&gs.tiles)

	append(&gs.entities, ..level.entities[:])
	append(&gs.colliders, ..level.colliders[:])
	append(&gs.tiles, ..level.tiles[:])

	gs.player_id = entity_create(
		{
			position = {
				x = level.player_spawn.?.x,
				y = level.player_spawn.?.y,
				width = playerWidth, 
				height = playerHeight
			},
			collider = {
				x = (playerWidth - colliderWidth) / 2,
				y = playerHeight - colliderHeight,
				width = colliderWidth,
				height = colliderHeight,
			},
			direction = Direction.RIGHT,
			move_speed = 200,
			flags = {.Debug_Draw},
		},
	)
}

read_map :: proc(filepath: string) {
	data, ok := os.read_entire_file(filepath, context.allocator)
	assert(ok, "error reading file")
	defer delete(data, context.allocator)

	file_contents := string(data)
	file_tokens := strings.fields(file_contents)
	map_width, _ := strconv.parse_int(file_tokens[0])
	map_height, _ := strconv.parse_int(file_tokens[1])

	tile_count: int = int(map_width * map_height)

	for token, i in file_tokens[2:] {
		x := tileWidth * f32(i % map_width)
		y := tileWidth * f32(i / map_width)

		if token == "cc" {
			entity_create(
				{
					position = {x = x, y = x, width = tileWidth, height = tileWidth},
					collider = {x = (tileWidth - colliderWidth) / 2, y = (tileWidth - colliderWidth) / 2, width = colliderWidth, height = colliderWidth},
					combined_collider = {x = (tileWidth - colliderWidth) / 2, y = (tileWidth - colliderWidth) / 2, width = colliderWidth, height = colliderWidth},
					direction = Direction.RIGHT,
					move_speed = 200,
					flags = {.Cart, .Debug_Draw},
					state = .EMPTY
				},
			)
			continue
		}
		if token == "pl" {
			gs.player_id = entity_create(
				{
					position = {x = x, y = y, width = playerWidth, height = playerHeight},
					collider = {
						x = (playerWidth - colliderWidth) / 2,
						y = playerHeight - colliderHeight,
						width = colliderWidth,
						height = colliderHeight,
					},
					direction = Direction.RIGHT,
					move_speed = 200,
					flags = {.Debug_Draw},
				},
			)
			continue
		}

		frame, ok := strconv.parse_int(token)
		if (ok && frame > 0) {

			tile: Entity
			tile.width = tileWidth
			tile.height = tileWidth
			tile.x = x
			tile.y = y
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

get_wall_animation :: proc(wall_frame: int) -> ^Animation {
	frame: int
	rotation: f32 = 0
	switch wall_frame {
	case 1:
		frame = 19 //top
	case 2:
		frame = 43 //bottom
	case 3:
		frame = 9 //top left corner
	case 4:
		frame = 14 //top right corner
	case 5:
		frame = 42 //bottom left corner
	case 6:
		frame = 45 //bottom right corner
	case 7:
		frame = 27 //bottom of top wall
	case 8:
		frame = 41 //left
	case 9:
		frame = 46 //right
	case 10:
		frame = 33 //int. top right
	case 11:
		frame = 38 //int. top left
	case 12:
		frame = 01 //right T
	case 13:
		frame = 06 //left T
	case 14:
		frame = 17 //right T2
	case 15:
		frame = 22 //left T2
	case 16:
		frame = 25 //left shadow wall
	case 17:
		frame = 31 //left shadow corner
	case 18:
		frame = 34 //int top left corner
	case 19:
		frame = 30 //right shadow wall
	case 20:
		frame = 29 //right shadow corner top
	case 21:
		frame = 37 //int top right corner
	}

	animation := new(Animation)
	animation.sprite_sheet = &walls_sheet
	frames := make([dynamic]int, 1, 1)
	frames[0] = frame
	animation.frames = frames

	return animation
}
