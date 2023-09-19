module main

import gg
import gx
import time

struct DialogPrompt {
mut:
	x            int
	y            int
	width        int
	height       int
	name         string
	padding      Padding
	fields       []TextBox
	field_labels []string
	buttons      []struct {
	mut:
		x       int
		y       int
		width   int
		height  int
		padding Padding
		label   string
		draw    fn (mut gg.Context) = unsafe { nil }
	}
}

fn DialogPrompt.new(name string, x int, y int, width int, height int, padding Padding, field_labels ...string) DialogPrompt {
	textbox_width := width - padding.left - padding.right
	textbox_height := 30
	textbox_padding := Padding{5, 5, 5, 5}
	textbox_x := x + padding.left
	textbox_y := y + padding.top + 50
	mut textboxes := []TextBox{cap: field_labels.len}
	for label in field_labels {
		textboxes << TextBox{
			x: int(textbox_x)
			y: int(textbox_y)
			width: int(textbox_width)
			height: textbox_height
			padding: textbox_padding
			placeholder: label
		}
	}
	mut prompt := DialogPrompt{
		x: x
		y: y
		width: width
		height: height
		name: name
		padding: padding
		fields: textboxes
		field_labels: field_labels
		buttons: [
			struct {
				y: int(y + height - padding.bottom - 50)
				width: 100
				height: 50
				padding: Padding{5, 5, 5, 5}
				label: 'Cancel'
			},
			struct {
				y: int(y + height - padding.bottom - 50)
				width: int(width / 2 - padding.left - padding.right)
				height: 50
				padding: Padding{5, 5, 5, 5}
				label: 'OK'
			},
		]
	}
	for i, mut button in prompt.buttons {
		button.x = int(x + padding.left + (button.width * i))
		button.draw = fn [i, mut button] (mut gfx gg.Context) {
			gfx.draw_rounded_rect_filled(button.x * i, button.y, button.width, button.height,
				5, gx.white)
			gfx.draw_text(int(button.x + button.padding.left), int(button.y + button.padding.top),
				button.label,
				color: gx.black
				size: 28
			)
		}
	}
	return prompt
}

fn (mut prompt DialogPrompt) update() {
	for mut field in prompt.fields {
		field.update()
	}
}

fn (mut prompt DialogPrompt) draw(mut gfx gg.Context) {
	gfx.draw_rounded_rect_filled(prompt.x, prompt.y, prompt.width, prompt.height, 5, gx.white)
	gfx.draw_text(int(prompt.x + prompt.padding.left), int(prompt.y + prompt.padding.top),
		prompt.name,
		color: gx.black
		size: 28
	)
	for mut field in prompt.fields {
		field.draw(mut gfx)
	}
	for mut button in prompt.buttons {
		button.draw(mut gfx)
	}
}

struct TextBox {
mut:
	x              int
	y              int
	width          int
	height         int
	padding        Padding
	placeholder    string   = 'Placeholder'
	border         gx.Color = gx.black
	cursor_visible bool
	stopwatch      time.StopWatch = time.new_stopwatch(auto_start: true)
}

fn (mut textbox TextBox) update() {
	if textbox.stopwatch.elapsed() > time.millisecond * 500 {
		textbox.cursor_visible = !textbox.cursor_visible
		textbox.stopwatch.restart()
	}
}

fn (mut textbox TextBox) draw(mut gfx gg.Context) {
	gfx.draw_rounded_rect_empty(textbox.x, textbox.y, textbox.width, textbox.height, 3,
		textbox.border)
	gfx.draw_text(int(textbox.x + textbox.padding.left), int(textbox.y + textbox.padding.top),
		textbox.placeholder, color: gx.gray, size: int(f32(textbox.height) / 1.5))
}
