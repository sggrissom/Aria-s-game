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
    rl.DrawRectangleRec(dest, rl.DARKGREEN);
    rl.DrawTexturePro(sprite_sheet.texture, sourceRec, dest, {0, 0}, 0, rl.WHITE);
}

render_entity :: proc(entity: ^Entity) {
    frameIndex : i32 = 0
    if (entity.is_animating) {
        frameIndex = i32(rl.GetTime() * f64(entity.animation.frames_per_second)) % i32(len(entity.animation.frames))
    }
    render_sprite(&(entity.animation.sprite_sheet), entity.animation.frames[frameIndex], entity.position)
}
