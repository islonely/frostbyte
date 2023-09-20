module main

import gg
import gx
import os

struct FileTree {
mut:
	x          f32
	y          f32
	width      f32
	root       string
	text_color gx.Color = gx.rgb(0xee, 0xee, 0xee)
	items      []&FileNode
	text_size  int = 18
}

struct FileNode {
mut:
	bounding_box gg.Rect
	name         string
	path         string
	is_dir       bool
	is_open      bool
	children     []&FileNode
	hover        bool
}

fn FileTree.new(x f32, y f32, width f32, root_path string) FileTree {
	mut items := []&FileNode{cap: 100}
	if list := os.ls(os.abs_path(root_path)) {
		if list.len > 0 {
			for item_path in list {
				items << &FileNode{
					path: os.join_path(root_path, item_path)
					name: os.base(item_path)
					is_dir: os.is_dir(os.join_path(root_path, item_path))
				}
				if items.last().is_dir {
					items[items.len - 1].get_items()
				}
			}
		}
	}
	return FileTree{
		x: x
		y: y
		width: width
		root: os.abs_path(root_path)
		items: items
	}
}

fn (mut filetree FileTree) event(evt &gg.Event) {
	if evt.typ == .mouse_down {
		for mut item in filetree.items {
			item.event(evt)
			if item.is_dir {
				if evt.mouse_x >= item.bounding_box.x - 15
					&& evt.mouse_x <= item.bounding_box.x + item.bounding_box.width + 5
					&& evt.mouse_y >= item.bounding_box.y - 5
					&& evt.mouse_y <= item.bounding_box.y + item.bounding_box.height + 5 {
					item.is_open = !item.is_open
				}
			}
		}
	} else if evt.typ == .mouse_move {
		for mut item in filetree.items {
			item.event(evt)
			item.hover = false
			if evt.mouse_x >= item.bounding_box.x
				&& evt.mouse_x <= item.bounding_box.x + item.bounding_box.width
				&& evt.mouse_y >= item.bounding_box.y
				&& evt.mouse_y <= item.bounding_box.y + item.bounding_box.height {
				item.hover = true
			}
		}
	}
}

fn (mut filetree FileTree) draw(mut gfx gg.Context) {
	mut i := 0
	for mut item in filetree.items {
		i += item.draw(int(filetree.x), int(filetree.y + (f32(filetree.text_size) * 1.5 * i)),
			filetree.text_size, filetree.text_color, mut gfx)
		i++
	}
}

fn (mut filenode FileNode) event(evt &gg.Event) {
	if evt.typ == .mouse_down {
		for mut item in filenode.children {
			item.event(evt)

			if item.is_dir {
				if evt.mouse_x >= item.bounding_box.x - 15
					&& evt.mouse_x <= item.bounding_box.x + item.bounding_box.width + 5
					&& evt.mouse_y >= item.bounding_box.y - 5
					&& evt.mouse_y <= item.bounding_box.y + item.bounding_box.height + 5 {
					item.is_open = !item.is_open
				}
			}
		}
	} else if evt.typ == .mouse_move {
		for mut item in filenode.children {
			item.event(evt)
			item.hover = false
			if evt.mouse_x >= item.bounding_box.x
				&& evt.mouse_x <= item.bounding_box.x + item.bounding_box.width
				&& evt.mouse_y >= item.bounding_box.y
				&& evt.mouse_y <= item.bounding_box.y + item.bounding_box.height {
				item.hover = true
			}
		}
	}
}

fn (mut filenode FileNode) draw(x int, y int, text_size int, color gx.Color, mut gfx gg.Context) int {
	mut i := 0
	if filenode.is_dir {
		if filenode.is_open {
			for mut child in filenode.children {
				i += child.draw(x + 10, int(y + (f32(text_size) * 1.5 * (i + 1))), text_size,
					color, mut gfx)
				i++
			}
			gfx.draw_triangle_filled(x - 15, y + 5, x - 5, y + 5, x - 10, y + 15, color)
		} else {
			gfx.draw_triangle_filled(x - 15, y + 5, x - 5, y + 10, x - 15, y + 15, color)
		}
	}

	filenode.bounding_box = gg.Rect{
		x: x
		y: y
		width: f32(filenode.name.len * text_size) / 1.8
		height: f32(text_size)
	}
	if filenode.hover {
		gfx.draw_rect_filled(x - 2, y - 2, filenode.bounding_box.width,
			filenode.bounding_box.height + 6, gx.Color{169, 190, 235, 90})
	}
	gfx.draw_text(x, y, filenode.name, size: 20, color: color)
	return i
}

// get_items sets the children of the FileNode to the items in the directory
// pointed to by the FileNode's path.
fn (mut filenode FileNode) get_items() {
	if !filenode.is_dir {
		return
	}
	mut children := []&FileNode{cap: 100}
	if list := os.ls(filenode.path) {
		if list.len > 0 {
			for item_path in list {
				children << &FileNode{
					path: os.join_path(filenode.path, item_path)
					name: os.base(item_path)
					is_dir: os.is_dir(os.join_path(filenode.path, item_path))
				}
				if children.last().is_dir {
					children[children.len - 1].get_items()
				}
			}
		}
	}
	filenode.children = children
}
