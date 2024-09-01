package main

gs : Game_State

food_sheet : Sprite_Sheet
cart_sheet : Sprite_Sheet
store_sheet : Sprite_Sheet
walls_sheet : Sprite_Sheet
player_sheet : Sprite_Sheet
player_walk_sheet : Sprite_Sheet
player_push_sheet : Sprite_Sheet

game_map : ^Map

AnimationStateKey :: struct {
    direction: Direction,
    state: EntityState,
}

cart_animation_map: map[DirectionStateKey]^Animation
player_animation_map: map[DirectionStateKey]^Animation

init_player_animations :: proc()
{
    cart_animation_map = make(map[DirectionStateKey]^Animation)
    player_animation_map = make(map[DirectionStateKey]^Animation)

    gs.food.animation = &Animation {
        sprite_sheet = &food_sheet,
        frames = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10},
        frames_per_second = 3,
    }

    CART_FRAMES :: 3

    cart_animations_map[{.LEFT, .EMPTY}] = Animation {
        sprite_sheet = &cart_sheet,
        frames = {3, 4, 5},
        frames_per_second = CART_FRAMES,
    }
    cart_animations_map[{.RIGHT, .EMPTY}] = Animation {
        sprite_sheet = &cart_sheet,
        frames = {6, 7, 8},
        frames_per_second = CART_FRAMES,
    }
    cart_animations_map[{.UP, .EMPTY}] = Animation {
        sprite_sheet = &cart_sheet,
        frames = {9, 10, 11},
        frames_per_second = CART_FRAMES,
    }
    cart_animations_map[{.DOWN, .EMPTY}] = Animation {
        sprite_sheet = &cart_sheet,
        frames = {0, 1, 2},
        frames_per_second = CART_FRAMES,
    }
    cart_animations_map[{.LEFT, .FULL}] = Animation {
        sprite_sheet = &cart_sheet,
        frames = {3+12, 4+12, 5+12},
        frames_per_second = CART_FRAMES,
    }
    cart_animations_map[{.RIGHT, .FULL}] = Animation {
        sprite_sheet = &cart_sheet,
        frames = {6+12, 7+12, 8+12},
        frames_per_second = CART_FRAMES,
    }
    cart_animations_map[{.UP, .FULL}] = Animation {
        sprite_sheet = &cart_sheet,
        frames = {9+12, 10+12, 11+12},
        frames_per_second = CART_FRAMES,
    }
    cart_animations_map[{.DOWN, .FULL}] = Animation {
        sprite_sheet = &cart_sheet,
        frames = {0+12, 1+12, 2+12},
        frames_per_second = CART_FRAMES,
    }
    player_animations_map[{.UP, .STILL}] = Animation {
        sprite_sheet = &player_sheet,
        frames = {1},
        frames_per_second = CART_FRAMES,
    }
    player_animations_map[{.DOWN, .STILL}] = Animation {
        sprite_sheet = &player_sheet,
        frames = {3},
        frames_per_second = CART_FRAMES,
    }
    player_animations_map[{.LEFT, .STILL}] = Animation {
        sprite_sheet = &player_sheet,
        frames = {2},
        frames_per_second = CART_FRAMES,
    }
    player_animations_map[{.RIGHT, .STILL}] = Animation {
        sprite_sheet = &player_sheet,
        frames = {0},
        frames_per_second = CART_FRAMES,
    }
    player_animations_map[{.UP, .WALK}] = Animation {
        sprite_sheet = &player_walk_sheet,
        frames = {6,7,8,9,10,11},
        frames_per_second = 6,
    }
    player_animations_map[{.DOWN, .WALK}] = Animation {
        sprite_sheet = &player_walk_sheet,
        frames = {18,19,20,21,22,23},
        frames_per_second = 6,
    }
    player_animations_map[{.LEFT, .WALK}] = Animation {
        sprite_sheet = &player_walk_sheet,
        frames = {12,13,14,15,16,17},
        frames_per_second = 6,
    }
    player_animations_map[{.RIGHT, .WALK}] = Animation {
        sprite_sheet = &player_walk_sheet,
        frames = {0,1,2,3,4,5},
        frames_per_second = 6,
    }
    player_animations_map[{.UP, .HOLD}] = Animation {
        sprite_sheet = &player_push_sheet,
        frames = {6,7,8,9,10,11},
        frames_per_second = 6,
    }
    player_animations_map[{.DOWN, .HOLD}] = Animation {
        sprite_sheet = &player_push_sheet,
        frames = {18,19,20,21,22,23},
        frames_per_second = 6,
    }
    player_animations_map[{.LEFT, .HOLD}] = Animation {
        sprite_sheet = &player_push_sheet,
        frames = {12,13,14,15,16,17},
        frames_per_second = 6,
    }
    player_animations_map[{.RIGHT, .HOLD}] = Animation {
        sprite_sheet = &player_push_sheet,
        frames = {0,1,2,3,4,5},
        frames_per_second = 6,
    }
}