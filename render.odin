#+feature dynamic-literals
package main

import rl "vendor:raylib"

render_tile :: proc(tile: ^Tile, texture: rl.Texture2D) {
    width: f32 = tileWidth
    height: f32 = tileWidth

    if tile.f == 1 || tile.f == 3 {
        width = -tileWidth
    } else if tile.f == 2 || tile.f == 3 {
        height = -tileWidth
    }

    rl.DrawTextureRec(
        texture,
        {tile.src.x, tile.src.y, width, height},
        tile.pos,
        rl.WHITE,
    )
}

render_entity :: proc(entity: ^Entity, dt: f32) {
    if .Removed in entity.flags do return 

    if entity.texture != nil {
        entity.animation_timer -= dt

        animation := entity.animations[entity.current_anim_name]
        if animation != nil {
            source := Rect {
                f32(entity.current_anim_frame) * animation.size.x,
                f32(animation.row) * animation.size.y,
                animation.size.x,
                animation.size.y,
            }

            rl.DrawTextureRec(entity.texture^, source, {entity.x, entity.y} - animation.offset, rl.WHITE)
        }
    }
    if .Debug_Draw in entity.flags {
        rl.DrawRectangleLinesEx(entity.position, 1, rl.GREEN)
        //rl.DrawRectangleLinesEx(get_static_collider(entity^), 1, rl.ORANGE)
    }
}

render_background :: proc() {
    for &tile in gs.tiles {
        render_tile(&tile, floor_texture)
    }
    for &wall in gs.walls {
        render_tile(&wall, walls_texture)
    }
}

render_foreground :: proc() {
    for &tile in gs.store {
        render_tile(&tile, store_texture)
    }
    for &tile in gs.walls_fore {
        render_tile(&tile, walls_texture)
    }
}

render_frame :: proc() {
    rl.BeginDrawing()
    rl.ClearBackground(BG_COLOR)
    rl.BeginMode2D(gs.cam)

    player := entity_get(gs.player_id)
    
    render_background()

    entities_to_render: []^Entity = make([]^Entity, len(gs.entities), context.temp_allocator)
    for i in 0..<len(gs.entities) {
        entities_to_render[i] = &gs.entities[i]
    }
    
    // sort by y
    for i in 1..<len(entities_to_render) {
        current := entities_to_render[i]
        j := i - 1
        for j >= 0 && entities_to_render[j].position.y > current.position.y {
            entities_to_render[j + 1] = entities_to_render[j]
            j -= 1
        }
        entities_to_render[j + 1] = current
    }
    
    for entity in entities_to_render {
        render_entity(entity, rl.GetFrameTime())
    }

    render_foreground()
    
    for s in gs.debug_shapes {
		switch v in s {
			case Debug_Line:
				rl.DrawLineEx(v.start, v.end, v.thickness, v.color)
			case Debug_Rect:
				rl.DrawRectangleLinesEx(
					{v.pos.x, v.pos.y, v.size.x, v.size.y},
					v.thickness,
					v.color,
				)
			case Debug_Circle:
				rl.DrawCircleLinesV(v.pos, v.radius, v.color)
        }
    }
    
    rl.EndMode2D()

    rl.DrawFPS(10, 10)
    y_line := 30
    for id in player.entity_ids {
        rl.DrawText(rl.TextFormat("touching id: %02i", int(id)), 10, i32(y_line), 10, rl.WHITE)
        y_line += 20
    }
    rl.DrawText(rl.TextFormat("animation: %s", player.current_anim_name), 10, i32(y_line), 10, rl.WHITE)
    rl.EndDrawing()

    clear(&gs.debug_shapes)
}