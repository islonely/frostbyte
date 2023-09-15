module core

import gg

// Background is all the pieces of a background.
struct Background {
	Coords
pub mut:
	textures []gg.Image
	parallax bool = true
}

// Background.new instantiates a new Background.
[inline]
pub fn Background.new(coords Coords, textures ...gg.Image) Background {
	return Background{
		Coords: coords
		textures: textures
	}
}
