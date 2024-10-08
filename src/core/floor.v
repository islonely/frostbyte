module core

import gg

// Floor represents a floor tile in the game.
struct Floor {
	Coords
	width   int = 1
	texture gg.Image
}

// Floor.new instantiates a new Floor object with the given texture.
fn Floor.new(texture gg.Image) Floor {
	return Floor{
		Coords:  Coords.new()
		texture: texture
	}
}
