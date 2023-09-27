module core

import gg

// Camera2D is a 2D camera.
struct Camera2D {
	Coords
pub mut:
	tilt f32
	zoom f32 = 1.5
}

// Camera2D.new instantiates a new Camera2D struct.
[inline]
fn Camera2D.new() Camera2D {
	return Camera2D{}
}

// Drawable2D is an item that can be drawn in accordance with a 2D camera.
interface Drawable2D {
	x int
	y int
	texture gg.Image
}
