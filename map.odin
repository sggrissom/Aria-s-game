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
		case "Wall_Decoration":
			// Tiles
			for auto_tile in layer.autoLayerTiles {
				append(&l.walls, Tile{auto_tile.px + l.level_min, auto_tile.src, auto_tile.f, layer.__tilesetRelPath})
			}
		case "Collision":
			x, y: f32
			for v, i in layer.intGridCsv {
				if v == 4 {
					append(&l.colliders, Rect{x, y, tileWidth, tileWidth})
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
	clear(&gs.walls)

	append(&gs.entities, ..level.entities[:])
	append(&gs.colliders, ..level.colliders[:])
	append(&gs.tiles, ..level.tiles[:])
	append(&gs.walls, ..level.walls[:])

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