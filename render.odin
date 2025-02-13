#+feature dynamic-literals
package main

import rl "vendor:raylib"

render_sprite :: proc(sprite_sheet: ^Sprite_Sheet, spriteToRender: int, dest: rl.Rectangle)
{
    sprite_width :f32 = sprite_sheet.sheet_size.x / f32(sprite_sheet.sprite_columns);
    sprite_height :f32 = sprite_sheet.sheet_size.y / f32(sprite_sheet.sprite_rows);

    sprite_row : int = spriteToRender / sprite_sheet.sprite_columns
    sprite_column : int = spriteToRender % sprite_sheet.sprite_columns

    sourceRec : rl.Rectangle = { sprite_width * f32(sprite_column), (sprite_height * f32(sprite_row)), sprite_width, sprite_height };
    rl.DrawTexturePro(sprite_sheet.texture, sourceRec, dest, {0, 0}, 0, rl.WHITE);
}

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

render_entity :: proc(entity: ^Entity) {
    if .Cart in entity.flags {
        entity.animation = cart_animations_map[{entity.direction, entity.state}]
    }
    if (entity.animation == nil) {
        return
    }
    frameIndex := 0
    if (.In_Motion in entity.flags && len(entity.animation.frames) > 1) {
        frameIndex = int(rl.GetTime() * f64(entity.animation.frames_per_second)) % int(len(entity.animation.frames))
    }
    if (.Debug_Draw in entity.flags) {
        if (entity.holding.item != nil) {
            rl.DrawRectangleLinesEx(get_static_collider(entity.holding.item^), 1, rl.BLUE);
        }
        rl.DrawRectangleLinesEx(get_static_collider(entity^), 1, rl.ORANGE);
        rl.DrawRectangleLinesEx(entity.position, 1, rl.GREEN);
    }
    assert(frameIndex < len(entity.animation.frames))
    render_sprite(entity.animation.sprite_sheet, entity.animation.frames[frameIndex], entity.position)
}

render_background :: proc() {
    for &tile in gs.tiles {
        render_tile(&tile, floor_sheet.texture)
    }
    for &wall in gs.walls {
        render_tile(&wall, walls_sheet.texture)
    }
}

render_foreground :: proc() {
    for &tile in gs.walls_fore {
        render_tile(&tile, walls_sheet.texture)
    }
}

render_frame :: proc() {
    rl.BeginDrawing()
    rl.ClearBackground(BG_COLOR)
    rl.BeginMode2D(gs.cam)

    animation :^Animation
    
    player := entity_get(gs.player_id)
    player.animation = player_animations_map[{player.direction, player.state}]
    
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
        render_entity(entity)
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
    rl.EndDrawing()

    clear(&gs.debug_shapes)
}