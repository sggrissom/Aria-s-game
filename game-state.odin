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

init_player_animations :: proc()
{
    player_anim_idle_right := new(Animation)
    player_anim_idle_right.size = {48, 96}
	player_anim_idle_right.offset = {10, 48}
	player_anim_idle_right.start = 0
	player_anim_idle_right.end = 5
	player_anim_idle_right.row = 1
	player_anim_idle_right.time = 0.5
	player_anim_idle_right.flags =  {.Loop}

    player_anim_idle_left := new(Animation)
    player_anim_idle_left.size = {48, 96}
	player_anim_idle_left.offset = {10, 48}
	player_anim_idle_left.start = 12
	player_anim_idle_left.end = 17
	player_anim_idle_left.row = 1
	player_anim_idle_left.time = 0.5
	player_anim_idle_left.flags =  {.Loop}

    player_anim_idle_up := new(Animation)
    player_anim_idle_up.size = {48, 96}
	player_anim_idle_up.offset = {10, 48}
	player_anim_idle_up.start = 6
	player_anim_idle_up.end = 11
	player_anim_idle_up.row = 1
	player_anim_idle_up.time = 0.5
	player_anim_idle_up.flags =  {.Loop}

    player_anim_idle_down := new(Animation)
    player_anim_idle_down.size = {48, 96}
	player_anim_idle_down.offset = {10, 48}
	player_anim_idle_down.start = 18
	player_anim_idle_down.end = 23
	player_anim_idle_down.row = 1
	player_anim_idle_down.time = 0.5
	player_anim_idle_down.flags =  {.Loop}

	animations := make(map[string]^Animation)
	animations = {
        "idle-left" = player_anim_idle_left,
        "idle-right" = player_anim_idle_right,
        "idle-up" = player_anim_idle_up,
        "idle-down" = player_anim_idle_down,
        "walk-left" = player_anim_idle_right,
        "walk-right" = player_anim_idle_right,
        "walk-up" = player_anim_idle_right,
        "walk-down" = player_anim_idle_right,
        "push-left" = player_anim_idle_right,
        "push-right" = player_anim_idle_right,
        "push-up" = player_anim_idle_right,
        "push-down" = player_anim_idle_right,
    }
    
    player := entity_get(gs.player_id)
    player.animations = animations
}