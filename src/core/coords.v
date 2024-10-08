module core

// Coords is a struct that holds 3D coordinates.
struct Coords {
pub mut:
	x f32
	y f32
	z f32
}

// Coords.new instantiates a new Coords struct.
@[inline]
fn Coords.new() Coords {
	return Coords{0, 0, 0}
}

// str returns a string representation of the Coords struct.
@[inline]
pub fn (c Coords) str() string {
	return 'X:${c.x} Y:${c.y} Z:${c.z}'
}
