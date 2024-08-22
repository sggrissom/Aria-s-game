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
    render_sprite(entity.animation.sprite_sheet, entity.animation.frames[frameIndex], entity.collider)
}

render_map :: proc() {
    for &tile in gs.solid_tiles {
        rl.DrawRectangleLinesEx(tile, 0.5, rl.RED)
    }
}

render_frame :: proc() {
    rl.BeginDrawing()
    rl.ClearBackground(BG_COLOR)

    rl.BeginMode2D(gs.cam)
    
    rl.DrawRectangleLinesEx(Rect{0, 0, 100, 100}, 0.5, rl.RED)

    animation :^Animation

    cart := entity_get(gs.cart_id)
    if (cart.direction == Direction.UP) {
        cart.animation = cart.is_empty ? &empty_up_cart : &full_up_cart
    }
    if (cart.direction == Direction.DOWN) {
        cart.animation = cart.is_empty ? &empty_down_cart : &full_down_cart
    }
    if (cart.direction == Direction.LEFT) {
        cart.animation = cart.is_empty ? &empty_left_cart : &full_left_cart
    }
    if (cart.direction == Direction.RIGHT) {
        cart.animation = cart.is_empty ? &empty_right_cart : &full_right_cart
    }

    render_map()
    render_entity(cart)
    render_entity(&gs.food)
    rl.DrawFPS(-30, -30)
    rl.EndMode2D()
    rl.EndDrawing()

}