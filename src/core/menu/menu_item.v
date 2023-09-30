module menu

import gx

// MenuItem is a menu item.
pub type MenuItem = ButtonMenuItem | CycleMenuItem | ToggleMenuItem

// ButtonMenuItem is a menu item that can be selected by pressing a button.
pub struct ButtonMenuItem {
__global:
	label  string
	border struct {
	__global:
		size   int
		color  gx.Color
		radius f32
	}

	on       ButtonMenuItemEvents
	disabled bool
	padding  Padding
}

// ButtonMenuItemEvents is a set of events that can be invoked by a
// `ButtonMenuItem`.
[params]
pub struct ButtonMenuItemEvents {
__global:
	click ?fn ()
}

// ButtonMenuItem.new creates a new `ButtonMenuItem` with the given label and
// function to invoke when the item is selected.
[inline]
pub fn ButtonMenuItem.new(label string, padding Padding, events ButtonMenuItemEvents) ButtonMenuItem {
	return ButtonMenuItem{
		label: label
		on: events
		padding: padding
	}
}

// CycleMenuItem is a menu item that can be cycled through by pressing a button.
//
pub struct CycleMenuItem {
mut:
	label          string
	values         []string
	selected_value int
	current_value  int
	on             CycleMenuItemEvents
	disabled       bool
	padding        Padding
}

// CycleMenuItemEvents is a set of events that can be invoked by a
// `CycleMenuItem`.
[params]
pub struct CycleMenuItemEvents {
__global:
	click ?fn (string)
	cycle ?fn (string)
}

// CycleMenuItem.new creates a new `CycleMenuItem` with the given label, values,
// and function to invoke when the item is selected.
[inline]
pub fn CycleMenuItem.new(label string, values []string, events CycleMenuItemEvents) CycleMenuItem {
	return CycleMenuItem{
		label: label
		values: values
		on: events
		padding: Padding.new(0)
	}
}

// cycle cycles the `CycleMenuItem` by the given distance. Positive distances
// cycle to the right, negative distances cycle to the left.
pub fn (mut item CycleMenuItem) cycle(distance int) {
	item.selected_value = (item.selected_value + distance) % item.values.len
	if cycle_fn := item.on.cycle {
		cycle_fn(item.value())
	}
}

// cycle_right cycles the `CycleMenuItem` to the right.
[inline]
pub fn (mut item CycleMenuItem) cycle_right() {
	item.cycle(1)
}

// cycle_left cycles the `CycleMenuItem` to the left.
[inline]
pub fn (mut item CycleMenuItem) cycle_left() {
	item.cycle(-1)
}

// value returns the currently selected value of the `CycleMenuItem`.
[inline]
pub fn (item CycleMenuItem) value() string {
	return item.values[item.selected_value]
}

// ToggleMenuItem is a menu item that can be toggled on and off by pressing a
// button.
pub struct ToggleMenuItem {
__global:
	label         string
	on            ToggleMenuItemEvents
	toggled_on    bool
	toggle_labels [2]string = ['Off', 'On']!
	padding       Padding
	disabled      bool
	border        struct {
	__global:
		size   int
		color  gx.Color
		radius f32
	}
}

// ToggleMenuItemEvents is a set of events that can be invoked by a
// `ToggleMenuItem`.
[params]
pub struct ToggleMenuItemEvents {
__global:
	toggle     ?fn (bool)
	toggle_off ?fn ()
	toggle_on  ?fn ()
}

// ToggleMenuItem.new creates a new `ToggleMenuItem` with the given label and
// functions to invoke when the item is selected.
pub fn ToggleMenuItem.new(label string, events ToggleMenuItemEvents) ToggleMenuItem {
	mut toggle_item := ToggleMenuItem{
		label: label
		on: events
	}
	if toggle_item.on.toggle == none {
		toggle_item.on.toggle = fn [mut toggle_item] (toggled_on bool) {
			if toggled_on {
				if toggle_on_fn := toggle_item.on.toggle_on {
					toggle_on_fn()
				}
			} else {
				if toggle_off_fn := toggle_item.on.toggle_off {
					toggle_off_fn()
				}
			}
		}
	}
	return toggle_item
}

// text returns the text to display for the `ToggleMenuItem`.
[inline]
pub fn (item ToggleMenuItem) text() string {
	return '${item.label}: ${item.toggle_labels[int(item.toggled_on)]}'
}
