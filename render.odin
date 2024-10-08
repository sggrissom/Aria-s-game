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
    assert(frameIndex < len(entity.animation.frames))
    render_sprite(entity.animation.sprite_sheet, entity.animation.frames[frameIndex], entity.position)
}

render_map :: proc() {
    for &tile in gs.solid_tiles {
        render_entity(&tile)
    }
}

render_frame :: proc() {
    rl.BeginDrawing()
    rl.ClearBackground(BG_COLOR)
    rl.BeginMode2D(gs.cam)

    animation :^Animation
    
    player := entity_get(gs.player_id)
    player.animation = player_animations_map[{player.direction, player.state}]
    
    render_map()

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