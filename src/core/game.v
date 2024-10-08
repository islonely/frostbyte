module core

import arrays
import gg
import gx
import math
import core.menu
import term
import time

const const_initial_width = 1920
const const_initial_height = 1080
const const_window_title = 'Frostbyte'

// GameState represents the current state of the game.
enum GameState {
	in_game
	paused
	main_menu
	main_menu_settings
}

// Game is the primary game object.
@[heap]
struct Game {
	gg.Context
pub mut:
	camera Camera2D
	state  GameState = .main_menu

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
	pub mut:
		fullscreen bool
		// todo: change this to ?int. V bug
		// currently not allowing it.
		fps_cap  int  = 60
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
		selected  int = 1
	}

	main_menu          menu.Menu
	main_settings_menu menu.Menu
}

// Game.new instantiates a new `Game` object.
pub fn Game.new() &Game {
	mut game := &Game{}
	game.Context = gg.new_context(
		bg_color:     gx.black
		width:        const_initial_width
		height:       const_initial_height
		window_title: const_window_title
		frame_fn:     frame
		init_fn:      init
		event_fn:     event
		user_data:    game
	)
	return game
}

@[inline]
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
	// main menu
	game.main_menu = menu.Menu.new(menu.ButtonMenuItem{
		label: 'Play'
		on:    menu.ButtonMenuItemEvents{
			click: fn [mut game] () {
				game.camera.x, game.camera.y = 0, 0
				game.state = .in_game
			}
		}
	}, menu.ButtonMenuItem{
		label: 'Settings'
		on:    menu.ButtonMenuItemEvents{
			click: fn [mut game] () {
				game.state = .main_menu_settings
			}
		}
	}, menu.ButtonMenuItem{
		label: 'Quit'
		on:    menu.ButtonMenuItemEvents{
			click: fn [mut game] () {
				game.quit()
			}
		}
	})
	game.main_menu.selected = menu.Cursor{
		text_color: gx.white
		annotation: ['-', '']!
	}
	game.set_text_cfg(size: game.main_menu.font_size)
	game.main_menu.center(mut game.Context)

	// main menu settings
	game.main_settings_menu = menu.Menu.new(menu.ToggleMenuItem.new('Fullscreen',
		toggle_on:  game.toggle_fullscreen
		toggle_off: game.toggle_fullscreen
	), menu.CycleMenuItem.new('FPS', 1, ['30', '60', '90', '120', '144', '165', 'unlimited'],
		click: fn [mut game] (value string) {
			game.settings.fps_cap = if value == 'unlimited' {
				-1
			} else {
				value.int()
			}
		}
	), menu.ButtonMenuItem{
		label: 'Back'
		on:    menu.ButtonMenuItemEvents{
			click: fn [mut game] () {
				game.state = .main_menu
			}
		}
	})
	game.main_settings_menu.center(mut game.Context)

	// init background images
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

	// weather
	game.weather = Weather{
		// precipitation: Precipitation.new(.rain, 50.0, int(f32(game.height) * 0.5), game)
		precipitation: Precipitation.new(.snow, 30.0, int(f32(game.height) * 0.33), game)
	}

	// characters
	init_characters(mut game) or { game.fatal_error('Failed to load characters: ${err.msg()}') }

	spawn game.debug()
}

// event is called every time an event is received.
fn event(evt &gg.Event, mut game Game) {
	if evt.typ == .resized {
		game.on_resize()
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
		.main_menu {
			game.main_menu.event(evt, mut game.Context)
		}
		.main_menu_settings {
			game.main_settings_menu.event(evt, mut game.Context)
		}
	}
}

// on_resize is called every time the window is resized. It scales the
// game's camera to fit the new window size.
fn (mut game Game) on_resize() {
	windown_size := if game.settings.fullscreen {
		gg.screen_size()
	} else {
		gg.window_size()
	}
	game.width = windown_size.width
	game.height = windown_size.height
	game.main_menu.center(mut game.Context)
	game.main_settings_menu.center(mut game.Context)
}

// frame is called every time a frame is rendered.
@[direct_array_access]
fn frame(mut game Game) {
	game.time.stopwatch.restart()
	game.begin()
	game.update()
	game.draw_frame()
	game.end()
	game.time.fps = 1.0 / game.time.delta
	arrays.rotate_right(mut game.time.fps_buffer, 1)
	game.time.fps_buffer[0] = game.time.fps
	if game.settings.fps_cap != -1 {
		time.sleep(time.second / game.settings.fps_cap)
	}
	game.frame_count++
	game.time.delta = f32(game.time.stopwatch.elapsed().seconds())
}

// update handles all the math that goes on in the game.
fn (mut game Game) update() {
	match game.state {
		.paused { game.update_paused() }
		.in_game { game.update_in_game() }
		.main_menu { game.update_main_menu() }
		.main_menu_settings { game.update_main_menu_settings() }
	}
}

// update_paused handles the math, logic, events, etc. that go on in the
// game while the game is in the `paused` state.
fn (mut game Game) update_paused() {
}

// update_in_game handles all the math that goes on in the game while
// the game is in the `in_game` state.
fn (mut game Game) update_in_game() {
	if game.pressed_keys[gg.KeyCode.left] {
		game.character().state = .running
		game.character().facing = .left
		game.character().x -= game.character().run_speed * game.time.delta
		if game.character().x < game.camera.x + int(f32(game.width) * 0.2) - game.character().width / 2 {
			game.camera.x -= game.character().run_speed * game.time.delta
		}
	} else if game.pressed_keys[gg.KeyCode.right] {
		game.character().state = .running
		game.character().facing = .right
		game.character().x += game.character().run_speed * game.time.delta
		if game.character().x > game.camera.x + int(f32(game.width) * 0.8) - game.character().width / 2 {
			game.camera.x += game.character().run_speed * game.time.delta
		}
	}
	game.characters.available[game.characters.selected].update(game.time.delta)

	game.weather.update(mut game)
}

// update_main_menu handles all the math that goes on in the game while
// the game is in the `main_menu` state.
fn (mut game Game) update_main_menu() {
	game.camera.x += 150 * game.time.delta
	game.main_menu.update(mut game.Context)
}

// update_main_menu_settings handles all the math that goes on in the game
// while the game is in the `main_menu_settings` state.
fn (mut game Game) update_main_menu_settings() {
	game.update_main_menu()
	game.main_settings_menu.update(mut game.Context)
}

// draw renders the game to the screen.
fn (mut game Game) draw_frame() {
	match game.state {
		.paused { game.draw_paused() }
		.in_game { game.draw_in_game() }
		.main_menu { game.draw_main_menu() }
		.main_menu_settings { game.draw_main_menu_settings() }
	}

	// draws a vertical and horizontal line through the center of the window.
	$if lines ? {
		game.draw_rect_filled(0, game.height / 2 - 1, game.width, 3, gx.white)
		game.draw_rect_filled(game.width / 2 - 1, 0, 3, game.height, gx.white)
	}
}

// draw_paused renders the game to the screen while the game is in the
// `paused` state.
fn (mut game Game) draw_paused() {
	game.draw_in_game()
	game.draw_overlay()
	game.draw_text(int(game.width / 2), int(game.height / 2), 'Paused',
		color:          gx.white
		size:           64
		align:          .center
		vertical_align: .middle
	)
}

// draw_in_game renders the game to the screen while the game is in the
// `in_game` state.
fn (mut game Game) draw_in_game() {
	game.draw_background()
	if game.settings.show_fps {
		game.draw_text(10, 10, 'FPS ${game.average_fps()}',
			color: gx.white
		)
	}

	mut character := game.character()
	character.draw(mut game)

	game.weather.draw(mut game)
}

// draw_main_menu renders the game to the screen while the game is in the
// `main_menu` state.
fn (mut game Game) draw_main_menu() {
	game.draw_background()
	game.main_menu.draw(mut game.Context)
}

// draw_main_menu_settings renders the game to the screen while the game is
// in the `main_menu_settings` state.
fn (mut game Game) draw_main_menu_settings() {
	game.draw_background()
	game.draw_overlay()
	game.main_settings_menu.draw(mut game.Context)
}

// draw_overlay draws a semi-transparent black overlay over the screen.
@[inline]
fn (mut game Game) draw_overlay() {
	game.draw_rect_filled(0, 0, game.width, game.height, gx.Color{0, 0, 0, 128})
}

// fatal_error prints an error message and quits the game.
fn (mut game Game) fatal_error(msg string) {
	eprintln(term.bright_red('error: ') + msg)
	game.quit()
}

// debug outputs information helpful for debugging if the game in ran
// with the -cg V flag.
@[if debug]
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

// toggle_fullscreen toggles the game's fullscreen state and resizes the
// game accordingly.
fn (mut game Game) toggle_fullscreen() {
	gg.toggle_fullscreen()
	game.settings.fullscreen = !game.settings.fullscreen
	game.on_resize()
}

// draw_2d draws a 2D drawable object to the screen relative to the camera.
fn (mut game Game) draw_2d(drawable Drawable2D) {
	x := drawable.x - game.camera.x
	y := drawable.y - game.camera.y
	game.draw_image(x, y, drawable.texture.width, drawable.texture.height, drawable.texture)
}
