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

cart_animations_map: map[AnimationStateKey]^Animation
player_animations_map: map[AnimationStateKey]^Animation

init_player_animations :: proc()
{
    cart_animations_map = make(map[AnimationStateKey]^Animation)
    player_animations_map = make(map[AnimationStateKey]^Animation)

    gs.food.animation = &Animation {
        sprite_sheet = &food_sheet,
        frames = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10},
        frames_per_second = 3,
    }

    CART_FRAMES :: 3

    cart_animations_map[{.LEFT, .EMPTY}] = new(Animation)
    cart_animations_map[{.LEFT, .EMPTY}].sprite_sheet = &cart_sheet
    cart_animations_map[{.LEFT, .EMPTY}].frames = {3, 4, 5}
    cart_animations_map[{.LEFT, .EMPTY}].frames_per_second = CART_FRAMES

    cart_animations_map[{.RIGHT, .EMPTY}] = new(Animation)
    cart_animations_map[{.RIGHT, .EMPTY}].sprite_sheet = &cart_sheet
    cart_animations_map[{.RIGHT, .EMPTY}].frames = {6, 7, 8}
    cart_animations_map[{.RIGHT, .EMPTY}].frames_per_second = CART_FRAMES

    cart_animations_map[{.UP, .EMPTY}] = new(Animation)
    cart_animations_map[{.UP, .EMPTY}].sprite_sheet = &cart_sheet
    cart_animations_map[{.UP, .EMPTY}].frames = {9, 10, 11}
    cart_animations_map[{.UP, .EMPTY}].frames_per_second = CART_FRAMES

    cart_animations_map[{.DOWN, .EMPTY}] = new(Animation)
    cart_animations_map[{.DOWN, .EMPTY}].sprite_sheet = &cart_sheet
    cart_animations_map[{.DOWN, .EMPTY}].frames = {0, 1, 2}
    cart_animations_map[{.DOWN, .EMPTY}].frames_per_second = CART_FRAMES

    cart_animations_map[{.LEFT, .FULL}] = new(Animation)
    cart_animations_map[{.LEFT, .FULL}].sprite_sheet = &cart_sheet
    cart_animations_map[{.LEFT, .FULL}].frames = {3+12, 4+12, 5+12}
    cart_animations_map[{.LEFT, .FULL}].frames_per_second = CART_FRAMES

    cart_animations_map[{.RIGHT, .FULL}] = new(Animation)
    cart_animations_map[{.RIGHT, .FULL}].sprite_sheet = &cart_sheet
    cart_animations_map[{.RIGHT, .FULL}].frames = {6+12, 7+12, 8+12}
    cart_animations_map[{.RIGHT, .FULL}].frames_per_second = CART_FRAMES

    cart_animations_map[{.UP, .FULL}] = new(Animation)
    cart_animations_map[{.UP, .FULL}].sprite_sheet = &cart_sheet
    cart_animations_map[{.UP, .FULL}].frames = {9+12, 10+12, 11+12}
    cart_animations_map[{.UP, .FULL}].frames_per_second = CART_FRAMES

    cart_animations_map[{.DOWN, .FULL}] = new(Animation)
    cart_animations_map[{.DOWN, .FULL}].sprite_sheet = &cart_sheet
    cart_animations_map[{.DOWN, .FULL}].frames = {0+12, 1+12, 2+12}
    cart_animations_map[{.DOWN, .FULL}].frames_per_second = CART_FRAMES

    player_animations_map[{.UP, .STILL}] = new(Animation)
    player_animations_map[{.UP, .STILL}].sprite_sheet = &player_sheet
    player_animations_map[{.UP, .STILL}].frames = {1}
    player_animations_map[{.UP, .STILL}].frames_per_second = CART_FRAMES

    player_animations_map[{.DOWN, .STILL}] = new(Animation)
    player_animations_map[{.DOWN, .STILL}].sprite_sheet = &player_sheet
    player_animations_map[{.DOWN, .STILL}].frames = {3}
    player_animations_map[{.DOWN, .STILL}].frames_per_second = CART_FRAMES

    player_animations_map[{.LEFT, .STILL}] = new(Animation)
    player_animations_map[{.LEFT, .STILL}].sprite_sheet = &player_sheet
    player_animations_map[{.LEFT, .STILL}].frames = {2}
    player_animations_map[{.LEFT, .STILL}].frames_per_second = CART_FRAMES

    player_animations_map[{.RIGHT, .STILL}] = new(Animation)
    player_animations_map[{.RIGHT, .STILL}].sprite_sheet = &player_sheet
    player_animations_map[{.RIGHT, .STILL}].frames = {0}
    player_animations_map[{.RIGHT, .STILL}].frames_per_second = CART_FRAMES
    
    player_animations_map[{.UP, .WALK}] = new(Animation)
    player_animations_map[{.UP, .WALK}].sprite_sheet = &player_walk_sheet
    player_animations_map[{.UP, .WALK}].frames = {6,7,8,9,10,11}
    player_animations_map[{.UP, .WALK}].frames_per_second = 6

    player_animations_map[{.DOWN, .WALK}] = new(Animation)
    player_animations_map[{.DOWN, .WALK}].sprite_sheet = &player_walk_sheet
    player_animations_map[{.DOWN, .WALK}].frames = {18,19,20,21,22,23}
    player_animations_map[{.DOWN, .WALK}].frames_per_second = 6

    player_animations_map[{.LEFT, .WALK}] = new(Animation)
    player_animations_map[{.LEFT, .WALK}].sprite_sheet = &player_walk_sheet
    player_animations_map[{.LEFT, .WALK}].frames = {12,13,14,15,16,17}
    player_animations_map[{.LEFT, .WALK}].frames_per_second = 6

    player_animations_map[{.RIGHT, .WALK}] = new(Animation)
    player_animations_map[{.RIGHT, .WALK}].sprite_sheet = &player_walk_sheet
    player_animations_map[{.RIGHT, .WALK}].frames = {0,1,2,3,4,5}
    player_animations_map[{.RIGHT, .WALK}].frames_per_second = 6
        
    player_animations_map[{.UP, .HOLD}] = new(Animation)
    player_animations_map[{.UP, .HOLD}].sprite_sheet = &player_push_sheet
    player_animations_map[{.UP, .HOLD}].frames = {6,7,8,9,10,11}
    player_animations_map[{.UP, .HOLD}].frames_per_second = 6

    player_animations_map[{.DOWN, .HOLD}] = new(Animation)
    player_animations_map[{.DOWN, .HOLD}].sprite_sheet = &player_push_sheet
    player_animations_map[{.DOWN, .HOLD}].frames = {18,19,20,21,22,23}
    player_animations_map[{.DOWN, .HOLD}].frames_per_second = 6

    player_animations_map[{.LEFT, .HOLD}] = new(Animation)
    player_animations_map[{.LEFT, .HOLD}].sprite_sheet = &player_push_sheet
    player_animations_map[{.LEFT, .HOLD}].frames = {12,13,14,15,16,17}
    player_animations_map[{.LEFT, .HOLD}].frames_per_second = 6

    player_animations_map[{.RIGHT, .HOLD}] = new(Animation)
    player_animations_map[{.RIGHT, .HOLD}].sprite_sheet = &player_push_sheet
    player_animations_map[{.RIGHT, .HOLD}].frames = {0,1,2,3,4,5}
    player_animations_map[{.RIGHT, .HOLD}].frames_per_second = 6
}