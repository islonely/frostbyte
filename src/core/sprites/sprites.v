module sprites

import gg
import stbi
import term

// SpriteSheet is a collection of sprites and the original image.
[noinit]
pub struct SpriteSheet {
pub:
	source stbi.Image
pub mut:
	cached_sprites map[string]Sprite
}

// SpriteSheet.new loads a sprite sheet from a file.
[inline]
pub fn SpriteSheet.new(path string) SpriteSheet {
	return SpriteSheet{
		source: stbi.load(path) or {
			eprintln(term.bright_red('error: ') + 'Failed to load sprite sheet: ' + path)
			exit(1)
		}
	}
}

// get_sprite returns a sprite from the sprite sheet.
pub fn (spritesheet SpriteSheet) get_sprite(rect gg.Rect) !Sprite {
	mut sprite_data := []u8{cap: rect.w * rect.h * spritesheet.source.nr_channels}
	row_len := rect.w * spritesheet.source.nr_channels
	for source_y in rect.y .. rect.h {
		row_start := source_y * row_len
		for source_x := rect.x; source_x < row_len; source_x++ {
			sprite_data << unsafe { &u8(spritesheet.source.data)[row_start + source_x] }
		}
	}

	return Sprite{
		stbi.Image: stbi.load_from_memory(sprite_data.data, sprite_data.len, desired_channels: spritesheet.source.nr_channels)!
		x: rect.x
		y: rect.y
	}
}

// CacheItem is an existing sprite or the dimensions of a new sprite.
pub type CacheItem = gg.Rect | Sprite

// CacheSpriteParams is the parameters for caching a sprite.
[params]
pub struct CacheSpriteParams {
__global:
	// The name of the sprite. Used for lookup when getting the sprite.
	name string = '<unnamed sprite>'
	// Whether to overrite an existing sprite with the same name.
	overrite bool = true
}

// cache_sprite caches a sprite from the sprite sheet for later use.
pub fn (mut spritesheet SpriteSheet) cache_sprite(cache_item CacheItem, params CacheSpriteParams) ! {
	if !params.overrite && params.name in spritesheet.cached_sprites {
		return error('Sprite with name "${params.name}" already exists.')
	}
		
	if cache_item is gg.Rect {
		spritesheet.cached_sprites[params.name] = spritesheet.get_sprite(cache_item)!
	} else if cache_item is Sprite {
		spritesheet.cached_sprites[params.name] = cache_item
	}
}

// get_cached_sprite returns a cached sprite from the sprite sheet.
pub fn (spritesheet SpriteSheet) get_cached_sprite(name string) !Sprite {
	if name !in spritesheet.cached_sprites {
		return error('Sprite with name "${name}" does not exist.')
	}
	return spritesheet.cached_sprites[name]
}

// Sprite is a single sprite from a sprite sheet.
[noinit]
pub struct Sprite {
	stbi.Image
pub mut:
	x int
	y int
}
