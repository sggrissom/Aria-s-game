package main

import rl "vendor:raylib"

render_sprite :: proc(sprite_sheet: ^Sprite_Sheet, spriteToRender: i32, dest: rl.Rectangle)
{
    sprite_width :f32 = sprite_sheet.sheet_size.x / f32(sprite_sheet.sprite_columns);
    sprite_height :f32 = sprite_sheet.sheet_size.y / f32(sprite_sheet.sprite_rows);

    sprite_row : i32 = spriteToRender / sprite_sheet.sprite_columns
    sprite_column : i32 = spriteToRender % sprite_sheet.sprite_columns

    // Source rectangle (part of the texture to use for drawing)
    sourceRec : rl.Rectangle = { sprite_width * f32(sprite_column), (sprite_height * f32(sprite_row)), sprite_width, sprite_height };
    rl.DrawTexturePro(sprite_sheet.texture, sourceRec, dest, {0, 0}, 0, rl.WHITE);
}

render_entity :: proc(entity: ^Entity) {
    frameIndex : i32 = 0
    if (entity.is_animating) {
        frameIndex = i32(rl.GetTime() * f64(entity.animation.frames_per_second)) % i32(len(entity.animation.frames))
    }
    render_sprite(&(entity.animation.sprite_sheet), entity.animation.frames[frameIndex], entity.position)
}

render_map :: proc(current_map: ^Map) {
    map_size := current_map.width * current_map.height

    for i :i32 = 0 ; i < map_size; i += 1{
        tileWidth :: 35
        dest : rl.Rectangle = { tileWidth * f32(i % current_map.width), tileWidth * f32(i / current_map.width), tileWidth, tileWidth };
        render_sprite(&food_sheet, current_map.tiles[i], dest)
    }
}

render_frame :: proc() {
    rl.BeginDrawing()
    rl.ClearBackground(rl.WHITE)
    render_entity(&gs.food)

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

    render_map(&game_map)
    render_entity(&gs.cart.entity)
    rl.DrawFPS(10,10)
    rl.EndDrawing()

}