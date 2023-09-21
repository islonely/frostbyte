module core

import arrays
import gg
import gx
import term
import time
import math

const (
	const_initial_width  = 1920
	const_initial_height = 1080
	const_window_title   = 'Frostbyte'
)

// GameState represents the current state of the game.
enum GameState {
	in_game
	paused
}

// Game is the primary game object.
[heap]
struct Game {
	gg.Context
pub mut:
	camera Camera2D
	state  GameState = .in_game

	frame_count u64
	time        struct {
	pub mut:
		fps        f32
		fps_buffer []f32 = []f32{len: 60}
		// measured in seconds
		delta     f32
		stopwatch time.StopWatch = time.new_stopwatch(auto_start: true)
	}

	textures struct {
	pub mut:
		background Background
		tileset    gg.Image
	}

	settings struct {
		fps_cap  ?int = 60
		show_fps bool = $if debug {
			true
		} $else {
			false
		}
	}

	weather    Weather
	characters struct {
	pub mut:
		available []&Character
		selected  int
	}
}

// Game.new instantiates a new `Game` object.
pub fn Game.new() &Game {
	mut game := &Game{}
	game.Context = gg.new_context(
		bg_color: gx.black
		width: core.const_initial_width
		height: core.const_initial_height
		window_title: core.const_window_title
		frame_fn: frame
		init_fn: init
		event_fn: event
		user_data: game
	)
	return game
}

[inline]
fn (game Game) character() &Character {
	return game.characters.available[game.characters.selected]
}

// average_fps returns the average FPS over the last 60 frames.
fn (game Game) average_fps() int {
	mut sum := f32(0)
	for fps in game.time.fps_buffer {
		sum += fps
	}
	return int(math.round(sum / game.time.fps_buffer.len))
}

// init is called once before the game is first started.
fn init(mut game Game) {
	mut bg_images := []gg.Image{cap: 3}
	for i in 0 .. 3 {
		bg_images << game.create_image_from_byte_array(const_textures['stringstar-fields']['background_${i}'].to_bytes()) or {
			game.fatal_error('Failed to load background image.')
			exit(1)
		}
	}
	game.textures.background = Background.new(Coords{0, 0, -1}, ...bg_images)
	game.textures.tileset = game.create_image_from_byte_array(const_textures['stringstar-fields']['tileset'].to_bytes()) or {
		game.fatal_error('Failed to load tileset image.')
		exit(1)
	}

	game.weather = Weather{
		// precipitation: Precipitation.new(.rain, 50.0, int(f32(game.height) * 0.5), game)
		precipitation: Precipitation.new(.snow, 30.0, int(f32(game.height) * 0.33), game)
	}
	game.characters.available << Knight.new(mut game.Context) or {
		game.fatal_error('Failed to load knight.')
		exit(1)
	}

	spawn game.debug()
}

// event is called every time an event is received.
fn event(evt &gg.Event, mut game Game) {
	if evt.typ == .resized {
		game.width, game.height = evt.window_width, evt.window_height
		if precipitation := game.weather.precipitation {
			game.weather.precipitation = Precipitation.new(precipitation.typ, precipitation.fall_speed,
				int(f32(game.height) * 0.5), game)
		}
		return
	}

	match game.state {
		.in_game {
			if evt.typ == .key_down {
				if evt.key_code == .escape {
					game.state = .paused
				}
			} else if evt.typ == .key_up {
				if !game.pressed_keys[gg.KeyCode.left] && !game.pressed_keys[gg.KeyCode.right] {
					game.character().state = .idle
				}
			}
		}
		.paused {
			if evt.typ == .key_down {
				if evt.key_code == .escape {
					game.state = .in_game
				}
			}
		}
	}
}

// frame is called every time a frame is rendered.
[direct_array_access]
fn frame(mut game Game) {
	game.time.stopwatch.restart()
	game.begin()
	game.update()
	game.draw_frame()
	game.end()
	game.time.fps = 1.0 / game.time.delta
	arrays.rotate_right(mut game.time.fps_buffer, 1)
	game.time.fps_buffer[0] = game.time.fps
	if fps_cap := game.settings.fps_cap {
		time.sleep(time.second / fps_cap)
	}
	game.frame_count++
	game.time.delta = f32(game.time.stopwatch.elapsed().seconds())
}

// update handles all the math that goes on in the game.
fn (mut game Game) update() {
	if game.state == .paused {
		return
	}

	// game.camera.x += 150 * game.time.delta
	if game.pressed_keys[gg.KeyCode.left] {
		game.character().state = .running
		game.character().facing = .left
		game.character().x -= game.character().run_speed * game.time.delta
		if game.character().x < game.camera.x + game.width / 8 {
			game.camera.x -= game.character().run_speed * game.time.delta
		}
	} else if game.pressed_keys[gg.KeyCode.right] {
		game.character().state = .running
		game.character().facing = .right
		game.character().x += game.character().run_speed * game.time.delta
		if game.character().x > game.camera.x + int(f32(game.width) / 1.75) {
			game.camera.x += game.character().run_speed * game.time.delta
		}
	}
	game.characters.available[game.characters.selected].update()

	game.weather.update(mut game)
}

// draw renders the game to the screen.
fn (mut game Game) draw_frame() {
	game.draw_background()
	if game.settings.show_fps {
		game.draw_text(10, 10, 'FPS ${game.average_fps()}',
			color: gx.white
		)
	}

	game.characters.available[game.characters.selected].draw(mut game)

	game.weather.draw(mut game)

	if game.state == .paused {
		game.draw_rect_filled(0, 0, game.width, game.height, gx.Color{0, 0, 0, 128})
		game.draw_text(int(game.width / 2), int(game.height / 2), 'Paused',
			color: gx.white
			size: 64
			align: .center
			vertical_align: .middle
		)
	}
}

// fatal_error prints an error message and quits the game.
fn (mut game Game) fatal_error(msg string) {
	eprintln(term.bright_red('error: ') + msg)
	game.quit()
}

// debug outputs information helpful for debugging if the game in ran
// with the -cg V flag.
[if debug]
fn (mut game Game) debug() {
	for {
		println('Delta: ${game.time.delta}')
		println('FPS: ${game.time.fps}')
		println('Camera: ${game.camera}')
		println('Frame: ${game.frame_count}\n')
		time.sleep(time.second * 3)
	}
}

// draw_background draws the background to the screen.
fn (mut game Game) draw_background() {
	for i, bg_texture in game.textures.background.textures {
		parallax := if game.textures.background.parallax {
			f32(game.textures.background.z - i) / 10.0
		} else {
			1.0
		}
		x := -int((game.textures.background.x - game.camera.x) * parallax) % game.width
		y := game.textures.background.y - game.camera.y
		game.draw_image(x, y, game.width, game.height, bg_texture)
		game.draw_image(x - game.width, y, game.width, game.height, bg_texture)
		game.draw_image(x + game.width, y, game.width, game.height, bg_texture)
	}
}

// draw_2d draws a 2D drawable object to the screen relative to the camera.
fn (mut game Game) draw_2d(drawable Drawable2D) {
	x := drawable.x - game.camera.x
	y := drawable.y - game.camera.y
	game.draw_image(x, y, drawable.texture.width, drawable.texture.height, drawable.texture)
}
