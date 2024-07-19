package main

import rl "vendor:raylib"

render_sprite :: proc(sprite_sheet: ^Sprite_Sheet, spriteToRender: int, dest: rl.Rectangle)
{
    sprite_width :f32 = sprite_sheet.sheet_size.x / f32(sprite_sheet.sprite_columns);
    sprite_height :f32 = sprite_sheet.sheet_size.y / f32(sprite_sheet.sprite_rows);

    sprite_row : int = spriteToRender / sprite_sheet.sprite_columns
    sprite_column : int = spriteToRender % sprite_sheet.sprite_columns

    // Source rectangle (part of the texture to use for drawing)
    sourceRec : rl.Rectangle = { sprite_width * f32(sprite_column), (sprite_height * f32(sprite_row)), sprite_width, sprite_height };
    rl.DrawTexturePro(sprite_sheet.texture, sourceRec, dest, {0, 0}, 0, rl.WHITE);
    rl.DrawRectangleLinesEx(dest, 0.5, rl.RED)
}

render_entity :: proc(entity: ^Entity) {
    if (entity.animation == nil) {
        return
    }
    frameIndex := 0
    if (entity.is_animating) {
        frameIndex = int(rl.GetTime() * f64(entity.animation.frames_per_second)) % int(len(entity.animation.frames))
    }
    render_sprite(entity.animation.sprite_sheet, entity.animation.frames[frameIndex], entity.position)
}

render_map :: proc() {
    for &tile in game_map.tiles {
        assert(tile.animation.frames[0] >= 0)
        render_entity(tile)
    }
}

render_frame :: proc() {
    rl.BeginDrawing()
    rl.ClearBackground(rl.WHITE)

    rl.BeginMode2D(gs.cam)

    animation :^Animation

    if (gs.cart.entity.direction == Direction.UP) {
        gs.cart.entity.animation = gs.cart.is_empty ? &empty_up_cart : &full_up_cart
    }
    if (gs.cart.entity.direction == Direction.DOWN) {
        gs.cart.entity.animation = gs.cart.is_empty ? &empty_down_cart : &full_down_cart
    }
    if (gs.cart.entity.direction == Direction.LEFT) {
        gs.cart.entity.animation = gs.cart.is_empty ? &empty_left_cart : &full_left_cart
    }
    if (gs.cart.entity.direction == Direction.RIGHT) {
        gs.cart.entity.animation = gs.cart.is_empty ? &empty_right_cart : &full_right_cart
    }

    render_map()
    render_entity(&gs.cart.entity)
    render_entity(&gs.food)
    rl.DrawFPS(-30, -30)
    rl.EndMode2D()
    rl.EndDrawing()

}