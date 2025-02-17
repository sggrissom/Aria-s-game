#+feature dynamic-literals
package main

import rl "vendor:raylib"

gs : Game_State

cart_texture : rl.Texture
store_texture : rl.Texture
walls_texture : rl.Texture
floor_texture : rl.Texture
player_texture : rl.Texture
player_walk_texture : rl.Texture
player_push_texture : rl.Texture
blue_char_texture : rl.Texture

make_player_animation :: proc(start, end, row: int) -> ^Animation {
    player_anim := new(Animation)
    player_anim.size = {48, 96}
	player_anim.offset = {10, 48}
	player_anim.start = start
	player_anim.end = end
	player_anim.row = row
	player_anim.time = 0.5
	player_anim.flags =  {.Loop}
    return player_anim
}

init_player_animations :: proc()
{
	animations := make(map[string]^Animation)
	animations = {
        "idle-left" = make_player_animation(12, 17, 1),
        "idle-right" = make_player_animation(0, 5, 1),
        "idle-up" = make_player_animation(6, 11, 1),
        "idle-down" = make_player_animation(18, 23, 1),
        "walk-left" = make_player_animation(12, 17, 2),
        "walk-right" = make_player_animation(0, 5, 2),
        "walk-up" = make_player_animation(6, 11, 2),
        "walk-down" = make_player_animation(18, 23, 2),
        "push-left" = make_player_animation(12, 17, 8),
        "push-right" = make_player_animation(0, 5, 8),
        "push-up" = make_player_animation(6, 11, 8),
        "push-down" = make_player_animation(18, 23, 8),
    }
    
    player := entity_get(gs.player_id)
    player.animations = animations
}