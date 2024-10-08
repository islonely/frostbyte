module menu

import gg
import gx
import math
import core.util { Easing }

// Menu is the menu that is drawn on the title screen.
pub struct Menu {
__global:
	x              int
	y              int
	menu_items     []MenuItem
	text_alignment TextAlignment
	selected       Cursor
	text_color     gx.Color = gx.rgb(0xba, 0xba, 0xba)
	font_size      int      = 40
}

// Menu.new creates a new `Menu` at the given position with the given menu items.
@[inline]
pub fn Menu.new(menu_items ...MenuItem) Menu {
	return Menu{
		menu_items: menu_items
	}
}

// center centers the menu relative to the window size.
pub fn (mut menu Menu) center(mut g gg.Context) {
	menu.x = g.width / 2 - menu.width(mut g) / 2
	menu.y = g.height / 2 - menu.height(mut g) / 2
}

// get_item_pos returns the position of the specified menu item.
pub fn (mut menu Menu) get_item_pos(raw_index int, mut g gg.Context) (int, int) {
	mut offset_y := 0
	index := raw_index % menu.menu_items.len
	for i, mut menu_item in menu.menu_items {
		match mut menu_item {
			ButtonMenuItem {
				if i == index {
					return menu.x + menu_item.padding.left, menu.y + offset_y +
						menu_item.padding.top
				}
				offset_y += g.text_height(menu_item.label) + menu_item.padding.top +
					menu_item.padding.bottom + (menu_item.border.size * 2)
			}
			CycleMenuItem {
				if i == index {
					return menu.x + menu_item.padding.left, menu.y + offset_y +
						menu_item.padding.top
				}
				offset_y += g.text_height(menu_item.label) + menu_item.padding.top +
					menu_item.padding.bottom
			}
			ToggleMenuItem {
				if i == index {
					return menu.x + menu_item.padding.left, menu.y + offset_y +
						menu_item.padding.top
				}
				offset_y += g.text_height(menu_item.text()) + menu_item.padding.top +
					menu_item.padding.bottom
			}
		}
	}
	return -1, -1
}

// get_current_item_pos returns the position of the currently selected item.
@[inline]
pub fn (mut menu Menu) get_current_item_pos(mut g gg.Context) (int, int) {
	return menu.get_item_pos(menu.selected.index, mut g)
}

// update updates the menu.
pub fn (mut menu Menu) update(mut g gg.Context) {
	current_item_x, current_item_y := menu.get_current_item_pos(mut g)
	menu.selected.target_x = current_item_x - menu.selected.margin - g.text_width(menu.selected.annotation[0])
	menu.selected.target_y = current_item_y

	menu.selected.update()
}

// event handles events for the menu.
pub fn (mut menu Menu) event(event &gg.Event, mut g gg.Context) {
	match event.typ {
		.key_down {
			match event.key_code {
				.up {
					menu.selected.start_x, menu.selected.start_y = menu.get_current_item_pos(mut g)
					menu.selected.index += if menu.selected.index - 1 >= 0 {
						-1
					} else {
						menu.menu_items.len - 1
					}
					menu.selected.target_x, menu.selected.target_y = menu.get_current_item_pos(mut g)
				}
				.down {
					menu.selected.start_x, menu.selected.start_y = menu.get_current_item_pos(mut g)
					menu.selected.index += if menu.selected.index + 1 < menu.menu_items.len {
						1
					} else {
						-menu.menu_items.len + 1
					}
					menu.selected.target_x, menu.selected.target_y = menu.get_current_item_pos(mut g)
				}
				.left {
					mut menu_item := menu.menu_items[menu.selected.index]
					match mut menu_item {
						CycleMenuItem {
							if menu_item.selected_value > 0 {
								menu_item.cycle_left()
							}
						}
						else {}
					}
				}
				.right {
					mut menu_item := menu.menu_items[menu.selected.index]
					match mut menu_item {
						CycleMenuItem {
							if menu_item.selected_value < menu_item.values.len - 1 {
								menu_item.cycle_right()
							}
						}
						else {}
					}
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
							menu_item.current_value = menu_item.selected_value
							if click_fn := menu_item.on.click {
								click_fn(menu_item.value())
							}
						}
						ToggleMenuItem {
							menu_item.toggled_on = !menu_item.toggled_on
							if toggle_fn := menu_item.on.toggle {
								toggle_fn(menu_item.toggled_on)
							} else {
								if menu_item.toggled_on {
									if toggle_on_fn := menu_item.on.toggle_on {
										toggle_on_fn()
									}
								} else {
									if toggle_off_fn := menu_item.on.toggle_off {
										toggle_off_fn()
									}
								}
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
@[inline]
pub fn (mut menu Menu) current_item() MenuItem {
	return menu.menu_items[menu.selected.index]
}

// width returns the width of the menu.
pub fn (mut menu Menu) width(mut g gg.Context) int {
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
			ToggleMenuItem {
				width := g.text_width(menu_item.text()) + menu_item.padding.left +
					menu_item.padding.right
				if width > max_width {
					max_width = width
				}
			}
		}
	}
	return max_width
}

// height returns the height of the menu.
pub fn (mut menu Menu) height(mut g gg.Context) int {
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
			ToggleMenuItem {
				height += g.text_height(menu_item.text()) + menu_item.padding.top +
					menu_item.padding.bottom
			}
		}
	}
	return height
}

// draw draws the menu to the screen.
@[direct_array_access]
pub fn (mut menu Menu) draw(mut g gg.Context) {
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
					size:  menu.font_size
					color: menu_item_color
				)
				if menu_item.border.size > 0 {
					g.draw_rounded_rect_empty(border_x, border_y, border_width, border_height,
						menu_item.border.radius, menu_item.border.color)
				}
				menu.selected.draw(mut g, menu.font_size)
			}
			CycleMenuItem {
				local_offset_x := menu_item.padding.left
				local_offset_y := menu_item.padding.top
				cycle_x := menu.x + local_offset_x
				cycle_y := menu.y + offset_y + local_offset_y
				offset_y += g.text_height(menu_item.label) + menu_item.padding.top +
					menu_item.padding.bottom

				value_color := if menu_item.selected_value == menu_item.current_value {
					menu.text_color
				} else {
					gx.rgb(0xca, 0x33, 0x5a)
				}
				label := '${menu_item.label}: '
				cycle_left := '< '
				cycle_right := ' >'
				value := menu_item.value()
				is_first_item := menu_item.selected_value == 0
				is_last_item := menu_item.selected_value == menu_item.values.len - 1
				g.draw_text(cycle_x, cycle_y, label,
					size:  menu.font_size
					color: menu_item_color
				)
				g.draw_text(cycle_x + g.text_width(label), cycle_y, cycle_left,
					size:  menu.font_size
					color: if is_first_item {
						menu.text_color
					} else {
						menu.selected.text_color
					}
				)
				g.draw_text(cycle_x + g.text_width(label) + g.text_width(cycle_left),
					cycle_y, value,
					size:  menu.font_size
					color: value_color
				)
				g.draw_text(cycle_x + g.text_width(label) + g.text_width(cycle_left) +
					g.text_width(value), cycle_y, cycle_right,
					size:  menu.font_size
					color: if is_last_item {
						menu.text_color
					} else {
						menu.selected.text_color
					}
				)
			}
			ToggleMenuItem {
				border_x := menu.x
				border_y := menu.y + offset_y
				local_offset_x := menu_item.padding.left + menu_item.border.size
				local_offset_y := menu_item.padding.top + menu_item.border.size
				toggler_x := menu.x + local_offset_x
				toggler_y := menu.y + offset_y + local_offset_y
				border_width := g.text_width(menu_item.text()) + menu_item.padding.left +
					menu_item.padding.right + (menu_item.border.size * 2)
				border_height := g.text_height(menu_item.text()) + menu_item.padding.top +
					menu_item.padding.bottom + (menu_item.border.size * 2)
				offset_y += border_height
				g.draw_text(toggler_x, toggler_y, menu_item.text(),
					size:  menu.font_size
					color: menu_item_color
				)
				if menu_item.border.size > 0 {
					g.draw_rounded_rect_empty(border_x, border_y, border_width, border_height,
						menu_item.border.radius, menu_item.border.color)
				}
			}
		}
	}
}

// Cursor is the cursor that is drawn on the title screen.
pub struct Cursor {
pub mut:
	// current position
	x f32
	y f32
	// animation start position
	start_x int
	start_y int
	// animation end position
	target_x int
	target_y int
	// animation progress
	percent_y f32
	percent_x f32
	// current item index in the parent menu
	index      int
	text_color gx.Color = gx.white
	// margin is the distance between the cursor and the menu item.
	margin int = 10
	// speed is the speed at which the cursor moves.
	speed      int = 10
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
	annotation [2]string = [2]string{}
}

// update updates the cursor position.
pub fn (mut selected Cursor) update() {
	selected.percent_y = math.abs(f32(selected.y - selected.start_y)) / math.abs(f32(selected.target_y - selected.start_y))
	selected.percent_x = math.abs(f32(selected.x - selected.start_x)) / math.abs(f32(selected.target_x - selected.start_x))
	// ease in
	relative_speed_y := selected.speed * Easing.ease_out_cubic(selected.percent_y) + 0.5
	relative_speed_x := selected.speed * Easing.ease_out_cubic(selected.percent_x) + 0.5
	if math.abs(selected.target_x - selected.x) > relative_speed_x {
		if selected.target_x > selected.x {
			selected.x += relative_speed_x
		} else {
			selected.x -= relative_speed_x
		}
	} else {
		selected.x = selected.target_x
	}
	if math.abs(selected.target_y - selected.y) > relative_speed_y {
		if selected.target_y > selected.y {
			selected.y += relative_speed_y
		} else {
			selected.y -= relative_speed_y
		}
	} else {
		selected.y = selected.target_y
	}
}

// draw draws the cursor to the screen.
pub fn (mut selected Cursor) draw(mut g gg.Context, font_size int) {
	g.draw_text(int(selected.x), int(selected.y), selected.annotation[0],
		size:  font_size
		color: selected.text_color
	)
	g.draw_text(int(selected.x) + g.text_width(selected.annotation[0]) + selected.margin,
		int(selected.y), selected.annotation[1],
		size:  font_size
		color: selected.text_color
	)
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
@[inline]
pub fn Padding.new(padding int) Padding {
	return Padding{padding, padding, padding, padding}
}

// Padding.yx creates a new `Padding` with the given padding on the y (top
// and bottom) and x (left and right) axes.
@[inline]
pub fn Padding.yx(y int, x int) Padding {
	return Padding{y, x, y, x}
}
