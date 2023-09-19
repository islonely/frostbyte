module main

import mouse
import gg

const screen_size = mouse.screen_size()

const maplemono = $embed_file('../assets/fonts/MapleMono-Regular.ttf')

fn main() {
	mut app := &LevelEditorApp{}
	app.Context = gg.new_context(
		width: int(f32(screen_size.width) * 0.8)
		height: int(f32(screen_size.height) * 0.8)
		window_title: 'Level Editor'
		font_bytes_normal: maplemono.to_bytes()
		user_data: app
		frame_fn: frame
		event_fn: event
		init_fn: init
	)
	app.run()
}

// init when the LevelEditorApp.Context.run() function is invoked.
fn init(mut app LevelEditorApp) {
	app.sidemenu = SideMenu.new(.left, app.window_size())
}

// frame is called every frame.
fn frame(mut app LevelEditorApp) {
	app.begin()
	{ // update
		app.sidemenu.update()
		for mut dialog in app.dialogs {
			dialog.update()
		}
	}
	{ // draw
		app.sidemenu.draw(mut app.Context)
		for mut dialog in app.dialogs {
			dialog.draw(mut app.Context)
		}
	}
	app.end()
}

// event is called when an event occurs.
fn event(evt &gg.Event, mut app LevelEditorApp) {
	app.sidemenu.event(evt, app.window_size())

	match evt.typ {
		.key_down {
			if evt.key_code == .n && app.key_modifiers == .ctrl && !app.key_repeat {
				width := 400
				height := 200
				x := (app.window_size().width - width) / 2
				y := (app.window_size().height - height) / 2
				app.dialogs << DialogPrompt.new('New File', x, y, width, height, Padding{10, 10, 10, 10},
					'Enter a name for the new file:')
			}
		}
		else {}
	}
}

// LevelEditorApp is the main application struct.
[heap]
struct LevelEditorApp {
	gg.Context
mut:
	sidemenu     SideMenu
	working_file string
	dialogs      []DialogPrompt
}

struct Padding {
mut:
	top    f32
	right  f32
	bottom f32
	left   f32
}
