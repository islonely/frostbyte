module core

import gx
import rand
import math

// Weather is a struct that holds the data for the weather.
struct Weather {
pub mut:
	precipitation ?&Precipitation
	wind_speed    f32
}

// Weather.new creates a new Weather.
[inline]
pub fn Weather.new() Weather {
	return Weather{
		precipitation: none
		wind_speed: 0.0
	}
}

// update updates the position of weather particles.
[direct_array_access]
fn (mut weather Weather) update(mut game Game) {
	if mut precipitation := weather.precipitation {
		match precipitation.typ {
			.rain {
				for i in 0 .. precipitation.particles.len {
					precipitation.particles[i].y += (precipitation.fall_speed * 10 * game.time.delta)
					precipitation.particles[i].x += (weather.wind_speed * 70 * game.time.delta)

					if precipitation.particles[i].y > game.camera.y + game.height {
						precipitation.particles[i].y = game.camera.y
					} else if precipitation.particles[i].y < game.camera.y {
						precipitation.particles[i].y = game.camera.y + game.height
					}

					if precipitation.particles[i].x > game.camera.x + game.width {
						precipitation.particles[i].x -= game.width
					} else if precipitation.particles[i].x < game.camera.x {
						precipitation.particles[i].x += game.width
					}
				}
			}
			.snow {
				fall_speed_min := precipitation.fall_speed * 0.5 * 10
				fall_speed_max := precipitation.fall_speed * 1.5 * 10
				for i in 0 .. precipitation.particles.len {
					precipitation.particles[i].y += (rand.f32_in_range(fall_speed_min,
						fall_speed_max) or {
						eprintln('error: failed to update precipitation particle position: ${err.msg()}')
						return
					} * game.time.delta)
					precipitation.particles[i].x += (weather.wind_speed * 70 * game.time.delta)

					if precipitation.particles[i].y > game.camera.y + game.height + 5 {
						precipitation.particles[i].y = game.camera.y - 5
					} else if precipitation.particles[i].y < game.camera.y - 5 {
						precipitation.particles[i].y = game.camera.y + game.height + 5
					}

					if precipitation.particles[i].x > game.camera.x + game.width {
						precipitation.particles[i].x -= game.width
					} else if precipitation.particles[i].x < game.camera.x {
						precipitation.particles[i].x += game.width
					}
				}
			}
		}
	}
}

// draw draws the weather to the screen.
fn (weather Weather) draw(mut game Game) {
	if mut precipitation := weather.precipitation {
		match precipitation.typ {
			.rain {
				for i in 0 .. precipitation.particles.len {
					coords := precipitation.particles[i]
					game.draw_line((coords.x - game.camera.x), (coords.y - game.camera.y),
						(coords.x - game.camera.x + weather.wind_speed), (
						coords.y - game.camera.y + 15), precipitation.color)
				}
			}
			.snow {
				for i in 0 .. precipitation.particles.len {
					coords := precipitation.particles[i]
					game.draw_line((coords.x - game.camera.x - 4), (coords.y - game.camera.y - 4),
						(coords.x - game.camera.x + 4), (coords.y - game.camera.y + 4),
						precipitation.color)
					game.draw_line((coords.x - game.camera.x + 4), (coords.y - game.camera.y - 4),
						(coords.x - game.camera.x - 4), (coords.y - game.camera.y + 4),
						precipitation.color)
					game.draw_line((coords.x - game.camera.x), (coords.y - game.camera.y - 5),
						(coords.x - game.camera.x), (coords.y - game.camera.y + 5), precipitation.color)
					game.draw_line((coords.x - game.camera.x - 5), (coords.y - game.camera.y),
						(coords.x - game.camera.x + 5), (coords.y - game.camera.y), precipitation.color)
				}
			}
		}
	}
}

// PrecipitationType is an enum of the different types of precipitation.
enum PrecipitationType {
	rain
	snow
}

// precipitation_type_to_color converts a PrecipitationType to a gx.Color.
fn precipitation_type_to_color(typ PrecipitationType) gx.Color {
	match typ {
		.rain {
			return gx.Color{0x00, 0x55, 0xea, 0xbf}
		}
		.snow {
			return gx.Color{0xff, 0xff, 0xff, 0xda}
		}
	}
}

// Precipitation is a struct that holds the data for a precipitation.
pub struct Precipitation {
	Coords
pub mut:
	typ PrecipitationType
	// Negative means wind is blowing to the left.
	// Positive means wind is blowing to the right.
	fall_speed f32
	color      gx.Color
	particles  []Coords = []Coords{cap: 1000}
}

// Precipitation.new creates a new Precipitation.
[inline]
pub fn Precipitation.new(typ PrecipitationType, fall_speed f32, particle_count int, game Game) &Precipitation {
	mut prec := &Precipitation{
		typ: typ
		fall_speed: fall_speed
		color: precipitation_type_to_color(typ)
		// Assumes a screen height of 1080p.
		particles: []Coords{cap: particle_count}
	}

	for _ in 0 .. prec.particles.cap {
		prec.particles << Coords{
			x: rand.f32_in_range(game.camera.x, game.camera.x + game.width) or {
				eprintln('error: failed to create precipitation particle. ${err.msg()}')
				exit(1)
			}
			y: rand.f32_in_range(game.camera.y, game.camera.y + game.height) or {
				eprintln('error: failed to create precipitation particle. ${err.msg()}')
				exit(1)
			}
			z: 100
		}
	}

	return prec
}
