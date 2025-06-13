player_api.register_model("character_slim.glb", {
	animation_speed = 1,
	textures = {"character.png"},
	animations = {
		-- Standard animations.
		stand     = {x = 0,   y = 2.66},
		lay       = {x = 5.4, y = 5.5, eye_height = 0.3, override_local = true,
			collisionbox = {-0.6, 0.0, -0.6, 0.6, 0.3, 0.6}},
		walk      = {x = 5.6, y = 6.27},
		mine      = {x = 6.3, y = 6.63},
		walk_mine = {x = 6.67, y = 7.33},
		sit       = {x = 2.7,  y = 5.37, eye_height = 0.8, override_local = true,
			collisionbox = {-0.3, 0.0, -0.3, 0.3, 1.0, 0.3}}
	},
	collisionbox = {-0.3, 0.0, -0.3, 0.3, 1.7, 0.3},
	stepheight = 1,
	eye_height = 1.47,
})

player_api.register_model("3d_armor_character_slim.glb", {
	animation_speed = 1,
	textures = {"character.png", "blank.png", "blank.png"},
	animations = {
		-- Standard animations.
		stand     = {x = 0,   y = 2.66},
		lay       = {x = 5.4, y = 5.5, eye_height = 0.3, override_local = true,
			collisionbox = {-0.6, 0.0, -0.6, 0.6, 0.3, 0.6}},
		walk      = {x = 5.6, y = 6.27},
		mine      = {x = 6.3, y = 6.63},
		walk_mine = {x = 6.67, y = 7.33},
		sit       = {x = 2.7,  y = 5.37, eye_height = 0.8, override_local = true,
			collisionbox = {-0.3, 0.0, -0.3, 0.3, 1.0, 0.3}}
	},
	collisionbox = {-0.3, 0.0, -0.3, 0.3, 1.7, 0.3},
	stepheight = 1,
	eye_height = 1.47,
})