#+feature dynamic-literals
package main

import rl "vendor:raylib"

RenderBlock :: struct {
    texture: ^rl.Texture2D,
    source: Rect,
    position: Vec2,
    tint: rl.Color
}

render_blocks ::proc(blocks: []RenderBlock) {
    for block in blocks {
        rl.DrawTextureRec(block.texture^, block.source, block.position, block.tint)
    }
}

render_tile :: proc(tile: ^Tile, texture: ^rl.Texture2D) -> (block: RenderBlock) {
    width: f32 = tileWidth
    height: f32 = tileWidth

    if tile.f == 1 || tile.f == 3 {
        width = -tileWidth
    } else if tile.f == 2 || tile.f == 3 {
        height = -tileWidth
    }

    return {
        texture,
        {tile.src.x, tile.src.y, width, height},
        tile.pos,
        rl.WHITE,
    }
}

render_entity :: proc(entity: ^Entity, dt: f32) -> (block: RenderBlock) {
    if .Removed in entity.flags do return 

    if .Debug_Draw in entity.flags {
        rl.DrawRectangleLinesEx(entity.position, 1, rl.GREEN)
        rl.DrawRectangleLinesEx(get_static_collider(entity^), 1, rl.ORANGE)
    }

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

            return {
                entity.texture,
                source,
                ({entity.x, entity.y} - animation.offset),
                rl.WHITE,
            }
        }
    }
    return {}
}

render_frame :: proc() {
    rl.BeginDrawing()
    rl.ClearBackground(BG_COLOR)
    rl.BeginMode2D(gs.cam)

    dt := rl.GetFrameTime()

    player := entity_get(gs.player_id)
    
    render_count := len(gs.entities) + len(gs.store) + len(gs.walls) + len(gs.walls_fore) + len(gs.tiles)
    blocks_to_render: []RenderBlock = make([]RenderBlock, render_count, context.temp_allocator)
    block_index := 0
    for i in 0..<len(gs.entities) {
        render_block := render_entity(&gs.entities[i], dt) 
        if render_block != {} {
            blocks_to_render[block_index] = render_block 
            block_index+=1
        }
    }
    for &tile, i in gs.store {
        blocks_to_render[block_index] = render_tile(&tile, &store_texture)
        block_index+=1
    }
    for &tile, i in gs.walls_fore {
        blocks_to_render[block_index] = render_tile(&tile, &walls_texture)
        block_index+=1
    }
    for &tile, i in gs.walls{
        blocks_to_render[block_index] = render_tile(&tile, &walls_texture)
        block_index+=1
    }
    for &tile, i in gs.tiles{
        blocks_to_render[block_index] = render_tile(&tile, &floor_texture)
        block_index+=1
    }
    for &collider in gs.colliders {
        rl.DrawRectangleLinesEx(collider, 1, rl.BLUE)
    }
    
    // sort by y
    for i in 1..<len(blocks_to_render) {
        current := blocks_to_render[i]
        j := i - 1
        for j >= 0 && blocks_to_render[j].position.y > current.position.y {
            blocks_to_render[j + 1] = blocks_to_render[j]
            j -= 1
        }
        blocks_to_render[j + 1] = current
    }
    
    render_blocks(blocks_to_render)
    
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