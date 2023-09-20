module main

import gg
import gx

// DraggableBorder is a border that can be dragged left or right.
struct DraggableBorder {
mut:
	x              f32
	y              f32
	width          f32
	height         f32
	max_drag_left  ?f32
	max_drag_right ?f32
	// color              gx.Color = gx.Color{100, 160, 245, 255}
	color              gx.Color = gx.rgba(0, 0, 0, 0)
	mouse_down_on_self bool
}

// DraggableBorder.new creates a new DraggableBorder.
[inline]
fn DraggableBorder.new(window_size gg.Size) DraggableBorder {
	return DraggableBorder{
		x: 0.0
		y: 0.0
		width: 5
		height: window_size.height
	}
}

// event handles events for the DraggableBorder allowing it to be dragged across
// the screen when clicked and dragged.
fn (mut border DraggableBorder) event(evt &gg.Event) {
	if evt.typ == .mouse_down {
		// 2 for padding/forgiveness. If you click slightly outside the border, it still counts.
		if (evt.mouse_x >= border.x - 2 && evt.mouse_x <= border.x + border.width + 2)
			&& (evt.mouse_y >= border.y - 2 && evt.mouse_y <= border.y + border.height + 2) {
			border.mouse_down_on_self = true
		}
	} else if evt.typ == .mouse_up {
		border.mouse_down_on_self = false
	} else if evt.typ == .mouse_move {
		if border.mouse_down_on_self {
			if evt.mouse_dx < 0 {
				if max_left := border.max_drag_left {
					if border.x + evt.mouse_dx < max_left {
						border.x = max_left
					} else {
						border.x += evt.mouse_dx
					}
				} else {
					border.x += evt.mouse_dx
				}
			} else if evt.mouse_dx > 0 {
				if max_right := border.max_drag_right {
					if border.x + border.width + evt.mouse_dx > max_right {
						border.x = max_right - border.width
					} else {
						border.x += evt.mouse_dx
					}
				} else {
					border.x += evt.mouse_dx
				}
			}
		}
	}
}

fn (mut border DraggableBorder) update() {
}

// draw draws the DraggableBorder.
[inline]
fn (border DraggableBorder) draw(mut gfx gg.Context) {
	gfx.draw_rect_filled(border.x, border.y, border.width, border.height, border.color)
}
