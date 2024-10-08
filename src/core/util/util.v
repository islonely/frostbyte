module util

@[noinit]
pub struct Easing {}

@[inline]
pub fn Easing.linear(t f32) f32 {
	return t
}

@[inline]
pub fn Easing.ease_in_quad(t f32) f32 {
	return t * t
}

@[inline]
pub fn Easing.ease_out_quad(t f32) f32 {
	return t * (2.0 - t)
}

@[inline]
pub fn Easing.ease_in_out_quad(t f32) f32 {
	return if t < 0.5 {
		2.0 * t * t
	} else {
		-1.0 + (4.0 - 2.0 * t) * t
	}
}

@[inline]
pub fn Easing.ease_in_cubic(t f32) f32 {
	return t * t * t
}

@[inline]
pub fn Easing.ease_out_cubic(t f32) f32 {
	t2 := t - 1.0
	return t2 * t2 * t2 + 1.0
}

@[inline]
pub fn Easing.ease_in_out_cubic(t f32) f32 {
	return if t < 0.5 {
		4.0 * t * t * t
	} else {
		f := 2.0 * t - 2.0
		0.5 * f * f * f + 1.0
	}
}

@[inline]
pub fn Easing.ease_in_quart(t f32) f32 {
	return t * t * t * t
}

@[inline]
pub fn Easing.ease_out_quart(t f32) f32 {
	t2 := t - 1.0
	return 1.0 - t2 * t2 * t2 * t2
}

@[inline]
pub fn Easing.ease_in_out_quart(t f32) f32 {
	return if t < 0.5 {
		8.0 * t * t * t * t
	} else {
		t2 := t - 1.0
		f := 2.0 * t2
		1.0 - 0.5 * f * f * f * f
	}
}

@[inline]
pub fn Easing.ease_in_quint(t f32) f32 {
	return t * t * t * t * t
}

@[inline]
pub fn Easing.ease_out_quint(t f32) f32 {
	t2 := t - 1.0
	return 1.0 + t2 * t2 * t2 * t2 * t2
}

@[inline]
pub fn Easing.ease_in_out_quint(t f32) f32 {
	return if t < 0.5 {
		16.0 * t * t * t * t * t
	} else {
		t2 := t - 1.0
		f := 2.0 * t2
		1.0 + 0.5 * f * f * f * f * f
	}
}
