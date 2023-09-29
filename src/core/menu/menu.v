module menu

import gg
import gx

// MainMenu is the menu that is drawn on the title screen.
pub struct MainMenu {
__global:
	x              int
	y              int
	menu_items     []MenuItem
	text_alignment TextAlignment
	selected       SelectedMenuItem
	text_color     gx.Color = gx.rgb(0xda, 0xda, 0xda)
	font_size      int      = 40
}

// MainMenu.new creates a new `MainMenu` at the given position with the given menu items.
[inline]
pub fn MainMenu.new(menu_items ...MenuItem) MainMenu {
	return MainMenu{
		menu_items: menu_items
	}
}

// event handles events for the menu.
pub fn (mut menu MainMenu) event(event &gg.Event) {
	match event.typ {
		.key_down {
			match event.key_code {
				.up {
					menu.selected.index = (menu.selected.index - 1) % menu.menu_items.len
				}
				.down {
					menu.selected.index = (menu.selected.index + 1) % menu.menu_items.len
				}
				.enter {
					mut menu_item := menu.menu_items[menu.selected.index]
					match mut menu_item {
						ButtonMenuItem {
							if click_fn := menu_item.on.click {
								click_fn()
							}
						}
						CycleMenuItem {
							if click_fn := menu_item.on.click {
								click_fn(menu_item.value())
							}
						}
					}
				}
				else {}
			}
		}
		else {}
	}
}

// current_item returns the currently selected menu item.
[inline]
pub fn (mut menu MainMenu) current_item() MenuItem {
	return menu.menu_items[menu.selected.index]
}

// width returns the width of the menu.
pub fn (mut menu MainMenu) width(mut g gg.Context) int {
	mut max_width := 0
	for mut menu_item in menu.menu_items {
		match mut menu_item {
			ButtonMenuItem {
				width := g.text_width(menu_item.label) + menu_item.padding.left +
					menu_item.padding.right + menu_item.border.size * 2
				if width > max_width {
					max_width = width
				}
			}
			CycleMenuItem {
				// +2 for the arrow characters and +2 for the space between
				// the arrow characters and the label.
				width := g.text_width(menu_item.label) + menu_item.padding.left +
					menu_item.padding.right + 4
				if width > max_width {
					max_width = width
				}
			}
		}
	}
	return max_width
}

// height returns the height of the menu.
pub fn (mut menu MainMenu) height(mut g gg.Context) int {
	mut height := 0
	for mut menu_item in menu.menu_items {
		match mut menu_item {
			ButtonMenuItem {
				height += g.text_height(menu_item.label) + menu_item.padding.top +
					menu_item.padding.bottom + (menu_item.border.size * 2)
			}
			CycleMenuItem {
				height += g.text_height(menu_item.label) + menu_item.padding.top +
					menu_item.padding.bottom
			}
		}
	}
	return height
}

// draw draws the menu to the screen.
[direct_array_access]
pub fn (mut menu MainMenu) draw(mut g gg.Context) {
	mut offset_y := 0
	for i, mut menu_item in menu.menu_items {
		is_selected_item := i == menu.selected.index
		menu_item_color := if is_selected_item {
			menu.selected.text_color
		} else {
			menu.text_color
		}
		match mut menu_item {
			ButtonMenuItem {
				border_x := menu.x
				border_y := menu.y + offset_y
				local_offset_x := menu_item.padding.left + menu_item.border.size
				local_offset_y := menu_item.padding.top + menu_item.border.size
				button_x := menu.x + local_offset_x
				button_y := menu.y + offset_y + local_offset_y
				border_width := g.text_width(menu_item.label) + menu_item.padding.left +
					menu_item.padding.right + (menu_item.border.size * 2)
				border_height := g.text_height(menu_item.label) + menu_item.padding.top +
					menu_item.padding.bottom + (menu_item.border.size * 2)
				offset_y += border_height
				g.draw_text(button_x, button_y, menu_item.label,
					size: menu.font_size
					color: menu_item_color
				)
				if menu_item.border.size > 0 {
					g.draw_rounded_rect_empty(border_x, border_y, border_width, border_height,
						menu_item.border.radius, menu_item.border.color)
				}
				annotation_margin := 10
				if menu.selected.annotation[0].len > 0 && is_selected_item {
					annotation_width := g.text_width(menu.selected.annotation[0])
					g.draw_text(border_x - annotation_margin - annotation_width, border_y +
						local_offset_y, menu.selected.annotation[0],
						size: menu.font_size
						color: menu.selected.text_color
					)
				}
				if menu.selected.annotation[1].len > 0 && is_selected_item {
					g.draw_text(border_x + border_width + annotation_margin, border_y +
						local_offset_y, menu.selected.annotation[1],
						size: menu.font_size
						color: menu.selected.text_color
					)
				}
			}
			else {
				println('notice: MainMenu has not implemented MenuItem type: ' +
					menu_item.type_name())
			}
		}
	}
}

// todo: replace with anonymous struct.
// vfmt currently has a bug that prevents this.
pub struct SelectedMenuItem {
mut:
	index      int
	text_color gx.Color
	// annotation is the character used to denote the selected item.
	/**
	 * example if annotation[0] is '>'
	 *   > selected
	 *     unselected
	 *     unselected
	 * example if annotation[1] is '<'
	 *     unselected <
	 *     selected
	 *     unselected
	**/
	annotation [2]string
}

// TextAlignment is the alignment of the text.
pub enum TextAlignment {
	left
	right
	center
	justify
}

// Padding is the extra distance given around an item (in pixels).
pub struct Padding {
__global:
	top    int
	right  int
	bottom int
	left   int
}

// Padding.new creates a new `Padding` with the same padding on all sides.
[inline]
pub fn Padding.new(padding int) Padding {
	return Padding{padding, padding, padding, padding}
}

// Padding.yx creates a new `Padding` with the given padding on the y (top
// and bottom) and x (left and right) axes.
[inline]
pub fn Padding.yx(y int, x int) Padding {
	return Padding{y, x, y, x}
}
