module main

import gg
import gx

// Side is the side of the screen that the menu slides out from.
enum Side {
	left
	right
}

// SideMenu is a menu that slides in from the left or right side of the screen.
struct SideMenu {
mut:
	x                f32
	y                f32
	width            f32
	side             Side
	text_color       gx.Color = gx.Color{0xee, 0xee, 0xee, 0xff}
	bg_color         gx.Color = gx.Color{0x11, 0x11, 0x1a, 0xff}
	draggable_border DraggableBorder
	filetree         FileTree
}

// SideMenu.new instantiates a new SideMenu.
fn SideMenu.new(side Side, window_size gg.Size) SideMenu {
	width := f32(window_size.width) * 0.15
	match side {
		.left {
			return SideMenu{
				x: 0
				y: 0
				width: width
				side: side
				draggable_border: DraggableBorder{
					x: width
					y: 0
					max_drag_left: 100
					max_drag_right: f32(window_size.width) - 100
					width: 5
					height: window_size.height
				}
				filetree: FileTree.new(40, 10, width - 50, @VMODROOT)
			}
		}
		.right {
			return SideMenu{
				x: f32(window_size.width) - width
				y: 0
				width: width
				side: side
				draggable_border: DraggableBorder{
					x: f32(window_size.width) - width - 5
					y: 0
					max_drag_left: 100
					max_drag_right: f32(window_size.width) - 100
					width: 5
					height: window_size.height
				}
				filetree: FileTree.new(40, 10, width - 50, @VMODROOT)
			}
		}
	}
}

fn (mut menu SideMenu) event(evt &gg.Event, window_size gg.Size) {
	menu.draggable_border.event(evt)
	menu.filetree.event(evt)
	if evt.typ == .mouse_move {
		match menu.side {
			.left {
				menu.width = menu.draggable_border.x
			}
			.right {
				menu.width = f32(window_size.width) - menu.draggable_border.x
				menu.x = f32(window_size.width) - menu.width
			}
		}
	} else if evt.typ == .mouse_scroll {
		if evt.mouse_x >= menu.x && evt.mouse_x <= menu.x + menu.width {
			menu.filetree.x += evt.scroll_x * 10
			menu.filetree.y += evt.scroll_y * 10
		}
	}
}

fn (mut menu SideMenu) update() {
	menu.draggable_border.update()
}

fn (mut menu SideMenu) draw(mut gfx gg.Context) {
	gfx.draw_rect_filled(menu.x, menu.y, menu.width, gfx.height, menu.bg_color)
	menu.filetree.draw(mut gfx)
	menu.draggable_border.draw(mut gfx)
}
