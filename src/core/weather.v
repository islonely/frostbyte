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
@[inline]
pub fn Weather.new() Weather {
	return Weather{
		precipitation: none
		wind_speed:    0.0
	}
}

// update updates the position of weather particles.
@[direct_array_access]
fn (mut weather Weather) update(mut game Game) {
	if mut precipitation := weather.precipitation {
		match precipitation.typ {
			.rain {
				for i in 0 .. precipitation.particles.len {
					precipitation.particles[i].y += (precipitation.particles[i].fall_speed * 10 * game.time.delta)
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
				for i in 0 .. precipitation.particles.len {
					precipitation.particles[i].y += (precipitation.particles[i].fall_speed * game.time.delta)
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
@[direct_array_access]
fn (weather Weather) draw(mut game Game) {
	if mut precipitation := weather.precipitation {
		match precipitation.typ {
			.rain {
				for i in 0 .. precipitation.particles.len {
					coords := precipitation.particles[i]
					game.draw_line((coords.x - game.camera.x), (coords.y - game.camera.y),
						(coords.x - game.camera.x + weather.wind_speed), (
						coords.y - game.camera.y + 15), precipitation.particles[i].color)
				}
			}
			.snow {
				for i in 0 .. precipitation.particles.len {
					coords := precipitation.particles[i]
					game.draw_square_filled((coords.x - game.camera.x), (coords.y - game.camera.y),
						precipitation.particles[i].size, precipitation.particles[i].color)
					// game.draw_line((coords.x - game.camera.x - 4), (coords.y - game.camera.y - 4),
					// 	(coords.x - game.camera.x + 4), (coords.y - game.camera.y + 4),
					// 	precipitation.color)
					// game.draw_line((coords.x - game.camera.x + 4), (coords.y - game.camera.y - 4),
					// 	(coords.x - game.camera.x - 4), (coords.y - game.camera.y + 4),
					// 	precipitation.color)
					// game.draw_line((coords.x - game.camera.x), (coords.y - game.camera.y - 5),
					// 	(coords.x - game.camera.x), (coords.y - game.camera.y + 5), precipitation.color)
					// game.draw_line((coords.x - game.camera.x - 5), (coords.y - game.camera.y),
					// 	(coords.x - game.camera.x + 5), (coords.y - game.camera.y), precipitation.color)
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
	particles  []PrecipitationParticle
}

// PrecipitationParticle is a struct that holds the data for a precipitation particle.
struct PrecipitationParticle {
	Coords
pub mut:
	fall_speed f32
	color      gx.Color
	size       f32
}

// Precipitation.new creates a new Precipitation.
@[inline]
pub fn Precipitation.new(typ PrecipitationType, fall_speed f32, particle_count int, game Game) &Precipitation {
	mut prec := &Precipitation{
		typ: typ
		// Assumes a screen height of 1080p.
		particles:  []PrecipitationParticle{cap: particle_count}
		fall_speed: fall_speed
	}

	for _ in 0 .. prec.particles.cap {
		prec.particles << match typ {
			.snow {
				mut clr := precipitation_type_to_color(typ)
				clr.a = u8(rand.int_in_range(128, 240) or { 200 })
				size := rand.f32_in_range(1.5, 6.0) or {
					println(err.msg())
					4.0
				}
				percent_size := math.max(size / 6.0, 0.7)
				fs := percent_size * fall_speed * 1.5
				PrecipitationParticle{
					size:       size
					fall_speed: fs
					color:      clr
					Coords:     Coords{
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
			}
			else {
				PrecipitationParticle{
					fall_speed: fall_speed
					color:      precipitation_type_to_color(typ)
					Coords:     Coords{
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
			}
		}
	}

	return prec
}
