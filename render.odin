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
    rl.DrawRectangleLinesEx(dest, 0.5, rl.WHITE)
}

render_entity :: proc(entity: ^Entity) {
    if (entity.animation == nil) {
        return
    }
    frameIndex := 0
    if (len(entity.animation.frames) > 1) {
        frameIndex = int(rl.GetTime() * f64(entity.animation.frames_per_second)) % int(len(entity.animation.frames))
    }
    assert(frameIndex < len(entity.animation.frames))
    render_sprite(entity.animation.sprite_sheet, entity.animation.frames[frameIndex], entity.position)
    
    rl.DrawRectangleLinesEx(get_static_collider(entity^), 0.5, rl.GREEN)
}

render_map :: proc() {
    for &tile in gs.solid_tiles {
        render_entity(&tile)
        rl.DrawRectangleLinesEx(tile, 0.5, rl.RED)
    }
}

render_frame :: proc() {
    rl.BeginDrawing()
    rl.ClearBackground(BG_COLOR)
    rl.BeginMode2D(gs.cam)

    animation :^Animation

    cart := entity_get(gs.cart_id)
    cart.animation = cart_animations_map[{cart.direction, cart.state}]
    
    player := entity_get(gs.player_id)
    player.animation = player_animations_map[{player.direction, player.state}]
    
    render_map()
    if (player.y < cart.y) {
        render_entity(player)
        render_entity(cart)
    } else {
        render_entity(cart)
        render_entity(player)
    }
    
    rl.EndMode2D()

    rl.DrawFPS(10, 10)
    rl.DrawText(rl.TextFormat("(%02.02f, %02.02f)", player.x, player.y), 10, 40, 20, rl.BLUE)
    rl.DrawText(rl.TextFormat("(%s)", player.state), 10, 80, 20, rl.BLUE)
    rl.EndDrawing()
}