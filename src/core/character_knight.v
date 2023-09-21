module core

import gg
import time

pub struct Knight {
pub mut:
	x              f32
	y              f32
	z              f32
	width          f32
	height         f32
	run_speed      f32 = 300
	state          CharacterState = .idle
	sprites        map[CharacterState]Sprites
	facing         Direction2D = .right
	anim_idx       int
	frame_duration ?time.Duration
	anim_stopwatch time.StopWatch = time.new_stopwatch(auto_start: true)
}

pub fn Knight.new(mut g gg.Context) !Knight {
	idle_img := g.create_image(@VMODROOT + '/src/assets/Knight_player/Idle_KG_1.png')!
	run_img := g.create_image(@VMODROOT + '/src/assets/Knight_player/Walking_KG_1.png')!
	jump_img := g.create_image(@VMODROOT + '/src/assets/Knight_player/Jump_KG_1.png')!
	return Knight{
		width: 200
		height: 128
		sprites: {
			.idle:    Sprites{
				image: &idle_img
				rects: []gg.Rect{len: 4, init: gg.Rect{index * 100, 0, 100, 64}}
			}
			.running: Sprites{
				image: &run_img
				rects: []gg.Rect{len: 7, init: gg.Rect{index * 100, 0, 100, 64}}
			}
			.jumping: Sprites{
				image: &jump_img
				rects: []gg.Rect{len: 6, init: gg.Rect{0, 0, 100, 64}}
			}
		}
	}
}

pub fn (mut knight Knight) update() {
	dur := knight.frame_duration or {
		time.millisecond * 700 / knight.sprites[knight.state].rects.len
	}

	knight.anim_idx = int(knight.anim_stopwatch.elapsed() / dur) % knight.sprites[knight.state].rects.len
}

pub fn (mut knight Knight) draw(mut game Game) {
	// game.draw_image_part(gg.Rect{
	// 	x: knight.x - game.camera.x
	// 	y: knight.y - game.camera.y
	// 	width: knight.width
	// 	height: knight.height
	// }, knight.sprites[knight.state].rects[knight.anim_idx], knight.sprites[knight.state].image)
	flip_x := if knight.facing == .left { true } else { false }
	game.draw_image_with_config(
		flip_x: flip_x
		img: knight.sprites[knight.state].image
		img_rect: gg.Rect{
			x: knight.x - game.camera.x
			y: knight.y - game.camera.y
			width: knight.width
			height: knight.height
		}
		part_rect: knight.sprites[knight.state].rects[knight.anim_idx]
	)
}
