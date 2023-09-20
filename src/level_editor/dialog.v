module main

import gg
import gx
import time
import rand

// Dialog is an interface for all dialogs.
interface Dialog {
mut:
	app &LevelEditorApp
	id string
	x int
	y int
	width int
	height int
	padding Padding
	bg_color gx.Color
	text_color gx.Color
	done bool
	cancelled bool
	event(&gg.Event)
	draw()
	update()
}

// DialogPrompt is a dialog that prompts the user for input.
struct DialogPrompt {
mut:
	app          &LevelEditorApp
	id           string = rand.uuid_v4()
	x            int
	y            int
	width        int
	height       int
	name         string
	padding      Padding
	bg_color     gx.Color = gx.Color{0x22, 0x22, 0x2a, 0xff}
	text_color   gx.Color = gx.Color{0xee, 0xee, 0xee, 0xff}
	fields       []TextBox
	field_labels []string
	done         bool
	cancelled    bool
}

// DialogPrompt.new creates a new DialogPrompt.
fn DialogPrompt.new(mut app LevelEditorApp, name string, x int, y int, width int, height int, padding Padding, field_labels ...string) DialogPrompt {
	textbox_width := width - padding.left - padding.right
	textbox_height := 30
	textbox_padding := Padding{5, 5, 5, 5}
	textbox_x := x + padding.left
	textbox_y := y + padding.top + 22 + padding.top
	mut textboxes := []TextBox{cap: field_labels.len}
	for label in field_labels {
		textboxes << TextBox{
			x: int(textbox_x)
			y: int(textbox_y)
			width: int(textbox_width)
			height: textbox_height
			padding: textbox_padding
			placeholder: label
			focused: true
		}
	}
	mut prompt := DialogPrompt{
		app: app
		x: x
		y: y
		width: width
		height: height
		name: name
		padding: padding
		fields: textboxes
		field_labels: field_labels
	}
	return prompt
}

// event handles events for the DialogPrompt.
fn (mut prompt DialogPrompt) event(evt &gg.Event) {
	if evt.typ == .key_down {
		if evt.key_code == .escape {
			prompt.cancelled = true
		} else if evt.key_code == .enter {
			prompt.done = true
		}
	}

	for mut field in prompt.fields {
		field.event(evt, mut prompt.app)
	}
}

// update updates the DialogPrompt.
fn (mut prompt DialogPrompt) update() {
	for mut field in prompt.fields {
		field.update()
	}
}

// draw draws the DialogPrompt.
fn (mut prompt DialogPrompt) draw() {
	prompt.app.draw_rounded_rect_filled(prompt.x, prompt.y, prompt.width, prompt.height,
		3, prompt.bg_color)
	prompt.app.draw_text(int(prompt.x + prompt.padding.left), int(prompt.y + prompt.padding.top),
		prompt.name,
		color: gx.Color{0xee, 0xee, 0xee, 0xff}
		size: 22
	)
	for mut field in prompt.fields {
		field.draw(mut prompt.app)
	}
}

// TextBox is a text box.
struct TextBox {
mut:
	x                 int
	y                 int
	width             int
	height            int
	padding           Padding
	placeholder       string = 'Placeholder'
	value             string
	border            gx.Color = gx.Color{0xee, 0xee, 0xee, 0xff}
	bg_color          gx.Color = gx.Color{0, 0, 0, 0}
	text_color        gx.Color = gx.Color{0xee, 0xee, 0xee, 0xff}
	placeholder_color gx.Color = gx.Color{0x88, 0x88, 0x88, 0xff}
	focused           bool
	cursor_visible    bool
	stopwatch         time.StopWatch = time.new_stopwatch(auto_start: true)
}

// event handles events for the TextBox.
fn (mut textbox TextBox) event(evt &gg.Event, mut app LevelEditorApp) {
	if evt.typ == .mouse_down {
		if evt.mouse_x >= textbox.x && evt.mouse_x <= textbox.x + textbox.width
			&& evt.mouse_y >= textbox.y && evt.mouse_y <= textbox.y + textbox.height {
			textbox.focused = true
			textbox.stopwatch.restart()
		} else {
			textbox.focused = false
		}
	} else if evt.typ == .key_down {
		if textbox.focused {
			if evt.key_code == .backspace {
				if app.key_modifiers == .ctrl {
					if textbox.value.contains(' ') {
						textbox.value = textbox.value.all_before_last(' ')
					} else {
						textbox.value = ''
					}
				} else {
					if textbox.value.len > 0 {
						textbox.value = textbox.value[0..textbox.value.len - 1]
					}
				}
			} else if evt.key_code == .enter {
				textbox.focused = false
			} else {
				// make sure we don't get .left_shift for example as a character
				if evt.key_code.str().len > 1 {
					match evt.key_code.str() {
						'_1' {
							if app.key_modifiers == .shift {
								textbox.value += '!'
							} else {
								textbox.value += '1'
							}
						}
						'_2' {
							if app.key_modifiers == .shift {
								textbox.value += '@'
							} else {
								textbox.value += '2'
							}
						}
						'_3' {
							if app.key_modifiers == .shift {
								textbox.value += '#'
							} else {
								textbox.value += '3'
							}
						}
						'_4' {
							if app.key_modifiers == .shift {
								textbox.value += '$'
							} else {
								textbox.value += '4'
							}
						}
						'_5' {
							if app.key_modifiers == .shift {
								textbox.value += '%'
							} else {
								textbox.value += '5'
							}
						}
						'_6' {
							if app.key_modifiers == .shift {
								textbox.value += '^'
							} else {
								textbox.value += '6'
							}
						}
						'_7' {
							if app.key_modifiers == .shift {
								textbox.value += '&'
							} else {
								textbox.value += '7'
							}
						}
						'_8' {
							if app.key_modifiers == .shift {
								textbox.value += '*'
							} else {
								textbox.value += '8'
							}
						}
						'_9' {
							if app.key_modifiers == .shift {
								textbox.value += '('
							} else {
								textbox.value += '9'
							}
						}
						'_0' {
							if app.key_modifiers == .shift {
								textbox.value += ')'
							} else {
								textbox.value += '0'
							}
						}
						'period' {
							if app.key_modifiers == .shift {
								textbox.value += '>'
							} else {
								textbox.value += '.'
							}
						}
						'comma' {
							if app.key_modifiers == .shift {
								textbox.value += '<'
							} else {
								textbox.value += ','
							}
						}
						'slash' {
							if app.key_modifiers == .shift {
								textbox.value += '?'
							} else {
								textbox.value += '/'
							}
						}
						'backslash' {
							if app.key_modifiers == .shift {
								textbox.value += '|'
							} else {
								textbox.value += '\\'
							}
						}
						'left_bracket' {
							if app.key_modifiers == .shift {
								textbox.value += '{'
							} else {
								textbox.value += '['
							}
						}
						'right_bracket' {
							if app.key_modifiers == .shift {
								textbox.value += '}'
							} else {
								textbox.value += ']'
							}
						}
						'grave_accent' {
							if app.key_modifiers == .shift {
								textbox.value += '~'
							} else {
								textbox.value += '`'
							}
						}
						'minus' {
							if app.key_modifiers == .shift {
								textbox.value += '_'
							} else {
								textbox.value += '-'
							}
						}
						'equal' {
							if app.key_modifiers == .shift {
								textbox.value += '+'
							} else {
								textbox.value += '='
							}
						}
						'semicolon' {
							if app.key_modifiers == .shift {
								textbox.value += ':'
							} else {
								textbox.value += ';'
							}
						}
						'apostrophe' {
							if app.key_modifiers == .shift {
								textbox.value += '"'
							} else {
								textbox.value += "'"
							}
						}
						'space' {
							textbox.value += ' '
						}
						else {}
					}
					return
				}

				lowercase := evt.key_code.str().bytes()[0]
				if app.key_modifiers == .shift {
					textbox.value += (lowercase - 32).ascii_str()
				} else {
					textbox.value += lowercase.ascii_str()
				}
			}
		}
	}
}

// update updates the TextBox.
fn (mut textbox TextBox) update() {
	// blinking cursor
	if textbox.stopwatch.elapsed() > time.millisecond * 500 {
		textbox.cursor_visible = !textbox.cursor_visible
		textbox.stopwatch.restart()
	}
}

// draw draws the TextBox.
fn (mut textbox TextBox) draw(mut app LevelEditorApp) {
	// border around the textbox
	app.draw_line(textbox.x, textbox.y + textbox.height, textbox.x + textbox.width, textbox.y +
		textbox.height, textbox.border)
	app.draw_line(textbox.x, textbox.y + textbox.height, textbox.x, textbox.y, textbox.border)
	app.draw_line(textbox.x + textbox.width, textbox.y + textbox.height, textbox.x + textbox.width,
		textbox.y, textbox.border)
	app.draw_line(textbox.x, textbox.y, textbox.x + textbox.width, textbox.y, textbox.border)

	// blinking cursor
	if textbox.focused && textbox.cursor_visible {
		app.draw_rect_filled(int(textbox.x + textbox.padding.left +
			textbox.value.len * int(f32(textbox.height) / 1.5 / 2.2)), int(textbox.y +
			textbox.padding.top), 2, textbox.height - textbox.padding.top - textbox.padding.bottom,
			textbox.border)
	}

	if textbox.value.len > 0 {
		// textbox value
		app.draw_text(int(textbox.x + textbox.padding.left), int(textbox.y + textbox.padding.top),
			textbox.value,
			color: textbox.text_color
			size: int(f32(textbox.height) / 1.5)
		)
	} else {
		// textbox placeholder
		app.draw_text(int(textbox.x + textbox.padding.left), int(textbox.y + textbox.padding.top),
			textbox.placeholder,
			color: textbox.placeholder_color
			size: int(f32(textbox.height) / 1.5)
		)
	}
}

struct DialogToast {
mut:
	app        &LevelEditorApp
	id         string = rand.uuid_v4()
	x          int
	y          int
	width      int
	height     int
	margin     Padding  = Padding{15, 15, 15, 15}
	padding    Padding  = Padding{5, 5, 5, 5}
	bg_color   gx.Color = gx.Color{0x11, 0x11, 0x1a, 0xff}
	text_color gx.Color = gx.Color{0xee, 0xee, 0xee, 0xff}
	title      string
	message    string
	lifetime   time.Duration  = time.second * 10
	stopwatch  time.StopWatch = time.new_stopwatch(auto_start: true)
	cancelled  bool
	done       bool
}

//
enum Anchor {
	top_left
	top_right
	bottom_left
	bottom_right
}

fn DialogToast.new(mut app LevelEditorApp, title string, message string, width int, height int, anchor Anchor) DialogToast {
	x, y := match anchor {
		.top_left {
			0, 0
		}
		.top_right {
			app.width - width, 0
		}
		.bottom_left {
			0, app.height - height
		}
		.bottom_right {
			app.width - width, app.height - height
		}
	}

	mut toast := DialogToast{
		app: app
		id: rand.uuid_v4()
		title: title
		message: message
		x: x
		y: y
		width: width
		height: height
	}
	return toast
}

fn (mut toast DialogToast) event(evt &gg.Event) {
	if evt.typ == .key_down {
		if evt.key_code == .escape {
			toast.cancelled = true
		}
	}
}

fn (mut toast DialogToast) update() {
	if toast.stopwatch.elapsed() > toast.lifetime {
		toast.done = true
	}
}

fn (mut toast DialogToast) draw() {
	toast.app.draw_rounded_rect_filled(toast.x - toast.margin.right, toast.y - toast.margin.bottom,
		toast.width, toast.height, 3, toast.bg_color)
	toast.app.draw_text(int(toast.x + toast.padding.left), int(toast.y + toast.padding.top),
		toast.title,
		color: toast.text_color
		size: 22
	)
	toast.app.draw_text(int(toast.x + toast.padding.left), int(toast.y + toast.padding.top + 22 +
		toast.padding.top), toast.message,
		color: toast.text_color
		size: 16
	)
}
