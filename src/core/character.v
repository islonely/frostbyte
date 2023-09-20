module core

import gg

interface Character {
mut:
	x f32
	y f32
	z f32
	width f32
	height f32
	run_speed f32
	state CharacterState
	sprites map[CharacterState]Sprites
	facing Direction2D
	draw(mut Game)
	update()
}

pub enum Direction2D {
	left
	right
}

struct Sprites {
pub mut:
	image &gg.Image
	rects []gg.Rect
}

// CharacterState represents the state of a character.
pub enum CharacterState {
	idle
	running
	walking
	jumping
	crouching
	sliding
	wall_sliding
	climbing
	melee_attack
	projectile_attack
	dead
	hanging
}
