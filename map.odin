#+feature dynamic-literals
package main

import "core:encoding/json"
import "core:log"
import "core:os"
import "core:slice"
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

    player_anim_idle := Animation {
		size   = {2688, 1920},
		offset = {0, 0},
		start  = 0,
		end    = 3,
		row    = 1,
		time   = 0.15,
		flags  = {.Loop},
	}

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
					x, y := entity.__worldX, entity.__worldY
					width, height := entity.width, entity.height

					cart := Entity{
						position = {x = x, y = y, width = width, height = height},
						collider = {x = (tileWidth - colliderWidth) / 2, y = (tileWidth - colliderWidth) / 2, width = colliderWidth, height = colliderWidth},
						combined_collider = {x = (tileWidth - colliderWidth) / 2, y = (tileWidth - colliderWidth) / 2, width = colliderWidth, height = colliderWidth},
						direction = Direction.RIGHT,
						move_speed = 200,
						flags = {.Cart, .Debug_Draw},
						state = .EMPTY,
						texture = &cart_texture,
						current_anim_name = "empty-right",
					}

					init_cart_animations(&cart)

					append(&l.entities, cart)
				}
			}
		case "Walls_Behind":
			for auto_tile in layer.autoLayerTiles {
				append(&l.walls, Tile{auto_tile.px + l.level_min, auto_tile.src, auto_tile.f, layer.__tilesetRelPath})
			}
		case "Walls_Front":
			for auto_tile in layer.autoLayerTiles {
				append(&l.walls_fore, Tile{auto_tile.px + l.level_min, auto_tile.src, auto_tile.f, layer.__tilesetRelPath})
			}
		case "Store":
			for auto_tile in layer.autoLayerTiles {
				tile := Tile{auto_tile.px + l.level_min, auto_tile.src, auto_tile.f, layer.__tilesetRelPath}
				append(&l.store, tile)
				//append(&l.colliders, Rect{tile.pos.x, tile.pos.y, tile.src.x, tile.src.y})
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

	consolidate_colliders(&l, level)
	make_shelf_colliders(&l, level)

	gs.level_defintions[l.iid] = l
}

 make_shelf_colliders :: proc(l: ^Level, level: ^LDtk_Level) {
 	wide_rect := Rect{ l.store[0].pos.x, l.store[0].pos.y, tileWidth, tileWidth }
 	wide_rects := make([dynamic]Rect, context.temp_allocator)

	for i in 1 ..< len(l.store) {
		rect := Rect{ l.store[i].pos.x, l.store[i].pos.y, tileWidth, tileWidth }

		if rect.x == wide_rect.x + wide_rect.width {
			wide_rect.width += tileWidth
		} else {
			append(&wide_rects, wide_rect)
			wide_rect = rect
		}
	}

	append(&wide_rects, wide_rect)

	slice.sort_by(wide_rects[:], proc(a, b: Rect) -> bool {
		if a.x != b.x do return a.x < b.x
		return a.y < b.y
	})

 	big_rects := make([dynamic]Rect, context.temp_allocator)
	big_rect := wide_rects[0]

	for i in 1 ..< len(wide_rects) {
		rect := wide_rects[i]

		if rect.x == big_rect.x &&
			big_rect.width == rect.width &&
			big_rect.y + big_rect.height == rect.y {
			big_rect.height += tileWidth
		} else {
			big_rect.x += level.worldX
			big_rect.y += level.worldY
			append(&big_rects, big_rect)
			big_rect = rect
		}
	}

	big_rect.x += level.worldX
	big_rect.y += level.worldY
	append(&big_rects, big_rect)
	

	for &rect in big_rects {
		//add margin
		offset : f32 = 30.0
		rect.height = rect.height - offset
		rect.width = rect.width - offset
		rect.x = rect.x + offset/2
		rect.y = rect.y + offset/2
		append(&l.colliders, rect)
	}
 }

consolidate_colliders :: proc(l: ^Level, level: ^LDtk_Level) {
	wide_rect := l.colliders[0]
	wide_rects := make([dynamic]Rect, context.temp_allocator)

	for i in 1 ..< len(l.colliders) {
		rect := l.colliders[i]

		if rect.x == wide_rect.x + wide_rect.width {
			wide_rect.width += tileWidth
		} else {
			append(&wide_rects, wide_rect)
			wide_rect = rect
		}
	}

	clear(&l.colliders)
	append(&wide_rects, wide_rect)

	slice.sort_by(wide_rects[:], proc(a, b: Rect) -> bool {
		if a.x != b.x do return a.x < b.x
		return a.y < b.y
	})

	big_rect := wide_rects[0]

	for i in 1 ..< len(wide_rects) {
		rect := wide_rects[i]

		if rect.x == big_rect.x &&
			big_rect.width == rect.width &&
			big_rect.y + big_rect.height == rect.y {
			big_rect.height += tileWidth
		} else {
			big_rect.x += level.worldX
			big_rect.y += level.worldY
			append(&l.colliders, big_rect)
			big_rect = rect
		}
	}

	big_rect.x += level.worldX
	big_rect.y += level.worldY
	append(&l.colliders, big_rect)
}

level_load :: proc(level: ^Level) {
	gs.level = level

	clear(&gs.entities)
	clear(&gs.colliders)
	clear(&gs.tiles)
	clear(&gs.walls)
	clear(&gs.walls_fore)
	clear(&gs.store)

	append(&gs.entities, ..level.entities[:])
	append(&gs.colliders, ..level.colliders[:])
	append(&gs.tiles, ..level.tiles[:])
	append(&gs.walls, ..level.walls[:])
	append(&gs.walls_fore, ..level.walls_fore[:])
	append(&gs.store, ..level.store[:])

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
			texture = &blue_char_texture,
			current_anim_name = "idle-right",
		},
	)
}