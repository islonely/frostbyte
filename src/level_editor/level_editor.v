module main

import mouse
import gg
import os

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
			if dialog.cancelled {
				app.dialogs = app.dialogs.filter(it.id != dialog.id)
				continue
			}
			if dialog.done {
				if mut dialog is DialogToast {
					app.dialogs = app.dialogs.filter(it.id != dialog.id)
					continue
				}

				if dialog.id == app.new_file_dialog_id {
					if mut dialog is DialogPrompt {
						app.working_file = os.abs_path(os.join_path(app.working_dir, dialog.fields[0].value))
						if os.exists(app.working_file) {
							msg := 'Cannot overwrite: ${app.working_file}'
							app.dialogs << DialogToast.new(mut app, 'New File Failure',
								msg, int(f32(msg.len * 16) / 2 + 20), 80, .bottom_right)
							app.dialogs = app.dialogs.filter(it.id != dialog.id)
							continue
						}
						os.create(app.working_file) or {
							app.dialogs << DialogToast.new(mut app, 'New File Failure',
								app.working_file, int(f32(app.working_file.len * 16) / 2 + 20),
								80, .bottom_right)
							app.dialogs = app.dialogs.filter(it.id != dialog.id)
							continue
						}
						app.dialogs << DialogToast.new(mut app, 'New File', app.working_file,
							int(f32(app.working_file.len * 16) / 2 + 20), 80, .bottom_right)
						app.dialogs = app.dialogs.filter(it.id != dialog.id)
						continue
					}
				}
			}
			dialog.update()
		}
	}
	{ // draw
		app.sidemenu.draw(mut app.Context)
		for mut dialog in app.dialogs {
			dialog.draw()
		}
	}
	app.end()
}

// event is called when an event occurs.
fn event(evt &gg.Event, mut app LevelEditorApp) {
	app.sidemenu.event(evt, app.window_size())
	for mut dialog in app.dialogs {
		dialog.event(evt)
	}

	match evt.typ {
		.key_down {
			if evt.key_code == .n && app.key_modifiers == .ctrl && !app.key_repeat {
				width := 500
				height := 80
				x := (app.window_size().width - width) / 2
				y := 20
				dialog := DialogPrompt.new(mut app, 'New File', x, y, width, height, Padding{10, 10, 10, 10},
					'Enter a name for the new file:')
				app.dialogs << dialog
				app.new_file_dialog_id = dialog.id
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
	sidemenu           SideMenu
	working_dir        string = @VMODROOT + '/levels'
	working_file       string
	dialogs            []Dialog
	new_file_dialog_id string
}

struct Padding {
mut:
	top    f32
	right  f32
	bottom f32
	left   f32
}
