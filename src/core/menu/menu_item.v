module menu

import gx

// MenuItem is a menu item.
pub type MenuItem = ButtonMenuItem | CycleMenuItem

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
	current  bool
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
	on             CycleMenuItemEvents
	disabled       bool
	current        bool
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

// value returns the currently selected value of the `CycleMenuItem`.
[inline]
pub fn (item CycleMenuItem) value() string {
	return item.values[item.selected_value]
}
