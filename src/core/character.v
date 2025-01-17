module core

import gg
import os
import rand
import time
import x.json2

const const_characters_dir = os.abs_path('./characters')

// init_characters loads characters locally allowing for custom characters to be added
// to the game.
fn init_characters(mut game Game) ! {
	if os.is_dir_empty(const_characters_dir) {
		return error('no characters found in ' + const_characters_dir)
	}

	os.walk(const_characters_dir, fn [mut game] (file string) {
		// if the file does not have an extension, skip it
		if !os.file_name(file).contains('.') {
			return
		}
		ext := file.split('.').last()
		if ext != 'json' {
			return
		}
		file_contents := os.read_file(file) or {
			println('failed to read file (${file}): ${err.msg()}')
			return
		}
		raw_json := json2.raw_decode(file_contents) or {
			println('failed to decode json (${file}): ${err.msg()}')
			return
		}.as_map()

		uuid := rand.uuid_v4()
		mut character := &Character{
			name:      raw_json['name'] or {
				println('Notice: character name missing (${file})')
				json2.Any(uuid)
			}.str()
			id:        uuid
			width:     raw_json['width'] or {
				println('Warning: character width missing (${file})')
				json2.Any(0)
			}.f32()
			height:    raw_json['height'] or {
				println('Warning: character height missing (${file})')
				json2.Any(0)
			}.f32()
			run_speed: raw_json['speed'] or {
				println('Warning: character speed missing (${file}); Using default of 300.')
				json2.Any(60000)
			}.f32()
		}
		raw_sprites := raw_json['sprites'] or {
			println('Warning: character sprites missing (${file})')
			return
		}
		sprites_state: for key, val in raw_sprites.as_map() {
			sprite_map := val.as_map()
			enum_val := CharacterState.from_string(key) or {
				println('Warning: invalid character state "${key}" (${file})')
				continue
			}
			img_path := os.abs_path('./characters/' + sprite_map['sprite-sheet-path'] or {
				println('Warning: character sprite image missing (${file})')
				continue
			}.str())
			img := game.create_image(img_path) or {
				println('Warning: failed to load character sprite image (${file}): ${img_path}')
				continue
			}
			frame_duration_ms := sprite_map['frame-duration'] or { json2.Any(0) }.int()
			character.sprites[enum_val].image = &img
			character.sprites[enum_val].oscillate = sprite_map['oscillate'] or { json2.Any(false) }.bool()
			if frame_duration_ms > 0 {
				character.sprites[enum_val].frame_duration = time.millisecond * frame_duration_ms
			}
			raw_rects := sprite_map['frames'] or {
				println('Warning: character sprite rects missing (${file})')
				continue
			}
			for raw_rect in raw_rects.arr() {
				rect_arr := raw_rect.arr()
				if rect_arr.len != 4 {
					println('Warning: invalid character sprite rect (${file})')
					continue sprites_state
				}
				character.sprites[enum_val].rects << gg.Rect{
					x:      rect_arr[0].int()
					y:      rect_arr[1].int()
					width:  rect_arr[2].int()
					height: rect_arr[3].int()
				}
			}
		}
		game.characters.available << character
	})
}

// Character is a Game character.
pub struct Character {
pub mut:
	name string
	// id used in case modders add characters with matching names
	id        string = rand.uuid_v4()
	x         f32
	y         f32
	z         f32
	velocity  struct {
	pub mut:
		x f32
		y f32
		z f32
	}
	width     f32
	height    f32
	run_speed f32            = 300
	gravity   f32            = 30
	state     CharacterState = .idle
	// todo: make this map[string]Sprites so that modders can add new states.
	sprites        map[CharacterState]Sprites
	facing         Direction2D = .right
	anim_idx       int
	anim_stopwatch time.StopWatch = time.new_stopwatch(auto_start: true)
}

// update handles the logic of the character.
pub fn (mut character Character) update(delta f32) {
	character.velocity.y += character.gravity * delta
	character.y += character.velocity.y
	character.x += character.velocity.x
	character.z += character.velocity.z

	dur := character.sprites[character.state].frame_duration or {
		time.millisecond * 700 / character.sprites[character.state].rects.len
	}

	oscillation_enabled := character.sprites[character.state].oscillate
	if oscillation_enabled {
		character.anim_idx = int(character.anim_stopwatch.elapsed() / dur) % (character.sprites[character.state].rects.len * 2)
		if character.anim_idx >= character.sprites[character.state].rects.len {
			character.anim_idx = character.sprites[character.state].rects.len - (character.anim_idx - character.sprites[character.state].rects.len) - 1
		}
	} else {
		character.anim_idx = int(character.anim_stopwatch.elapsed() / dur) % character.sprites[character.state].rects.len
	}
}

// draw draws the character's current animation frame.
pub fn (mut character Character) draw(mut game Game) {
	flip_x := if character.facing == .left { true } else { false }
	game.draw_image_with_config(
		flip_x:    flip_x
		img:       character.sprites[character.state].image
		img_rect:  gg.Rect{
			x:      character.x - game.camera.x
			y:      character.y - game.camera.y
			width:  character.width
			height: character.height
		}
		part_rect: character.sprites[character.state].rects[character.anim_idx]
	)
}

// Direction2D represents a direction something can face in 2D space.
pub enum Direction2D {
	left
	right
}

// Sprites represents a set of sprites for a character.
struct Sprites {
pub mut:
	// The spritesheet image for the character.
	image &gg.Image
	// The position and size of each sprite in the spritesheet.
	rects []gg.Rect
	// Makes the animation starts playing through the sprites in reverse order
	// once the end is reaced instead of looping back to the beginning.
	oscillate bool
	// How long each frame of the animation should be displayed for.
	frame_duration ?time.Duration
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
