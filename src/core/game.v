module core

import gg
import gx

const (
	const_initial_width  = 1280
	const_initial_height = 720
	const_window_title   = 'Frostbyte'
)

enum GameState {
	in_game
}

[heap]
struct Game {
	gg.Context
pub mut:
	state GameState = .in_game
}

pub fn Game.new() &Game {
	mut game := &Game{}
	game.Context = gg.new_context(
		bg_color: gx.black
		width: core.const_initial_width
		height: core.const_initial_height
		window_title: core.const_window_title
		frame_fn: frame
	)
	return game
}

fn frame(mut game Game) {
	game.begin()
	game.end()
}
