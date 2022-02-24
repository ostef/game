#import "Core";

#load "crt.jai";
#load "approx.jai";
#load "easing.jai";
#load "rect.jai";
#load "rgba.jai";
#load "trig.jai";

F32_MIN :: 0h0080_0000;
F32_MAX :: 0h7f7f_ffff;
F32_MIN_SUBNORMAL :: 0h0000_0001;
F32_MAX_SUBNORMAL :: 0h007f_ffff;
F32_POSITIVE_INFINITY :: 0h7f80_0000;
F32_NEGATIVE_INFINITY :: 0hff80_0000;
F32_NAN :: 0h7fc0_0000;
F32_EPSILON :: 0h3400_0000;

F32_MANTISSA_BITS :: 23;
F32_EXPONENT_BITS :: 8;
F32_EXPONENT_BIAS :: 127;

F64_MIN :: 0h0010_0000_0000_0000;
F64_MAX :: 0h7fef_ffff_ffff_ffff;
F64_MIN_SUBNORMAL :: 0h0000_0000_0000_0001;
F64_MAX_SUBNORMAL :: 0h000f_ffff_ffff_ffff;
F64_POSITIVE_INFINITY :: 0h7ff0_0000_0000_0000;
F64_NEGATIVE_INFINITY :: 0hfff0_0000_0000_0000;
F64_NAN :: 0h7ff8_0000_0000_0000;
F64_EPSILON :: 0h3cb0_0000_0000_0000;

F64_MANTISSA_BITS :: 52;
F64_EXPONENT_BITS :: 11;
F64_EXPONENT_BIAS :: 1023;

PI    : f32 : 3.1415927;
PI64  : f64 : 3.141592653589793;

ieee_decompose :: inline (f : f32) -> sign : bool, exponent : u64, mantissa : u64
	#no_context
{
	as_u32 := <<cast (*u32) *f;
	sign     := ((as_u32 >> (F32_MANTISSA_BITS + F32_EXPONENT_BITS)) & 1) != 0;
	exponent := ((as_u32 >> F32_MANTISSA_BITS) & ((1 << F32_EXPONENT_BITS) - 1));
	mantissa := as_u32 & ((1 << F32_MANTISSA_BITS) - 1);

	return sign, exponent, mantissa;
}

ieee_decompose :: inline (f : f64) -> sign : bool, exponent : u64, mantissa : u64
	#no_context
{
	as_u64 := <<cast (*u64) *f;
	sign     := ((as_u64 >> (F64_MANTISSA_BITS + F64_EXPONENT_BITS)) & 1) != 0;
	exponent := ((as_u64 >> F64_MANTISSA_BITS) & ((1 << F64_EXPONENT_BITS) - 1));
	mantissa := as_u64 & ((1 << F64_MANTISSA_BITS) - 1);

	return sign, exponent, mantissa;
}

is_nan :: inline (f : f64) -> bool #must
	#no_context
{
	s, e, m := ieee_decompose (f);

	return e == ((1 << F64_EXPONENT_BITS) - 1) && m != 0;
}

is_inf :: inline (f : f64) -> bool #must
	#no_context
{
	s, e, m := ieee_decompose (f);

	return e == ((1 << F64_EXPONENT_BITS) - 1) && m == 0;
}

is_nan :: inline (f : f32) -> bool #must
	#no_context
{
	s, e, m := ieee_decompose (f);

	return e == ((1 << F32_EXPONENT_BITS) - 1) && m != 0;
}

is_inf :: inline (f : f32) -> bool #must
	#no_context
{
	s, e, m := ieee_decompose (f);

	return e == ((1 << F32_EXPONENT_BITS) - 1) && m == 0;
}

round :: inline (x : $T) -> T #must
	#no_context
{
	return cast (T) (cast (int) (x + sign (x) * 0.5));
}

floor :: inline (x : $T) -> T #must
	#no_context
{
	i := cast (int) round (x);
	diff := x - i;

	return cast (T) (i - cast (int) (diff < 0));
}

ceil :: inline (x : $T) -> T #must
	#no_context
{
	i := cast (int) round (x);
	diff := i - x;

	return cast (T) (i + cast (int) (diff < 0));
}

wrap :: inline (a : int, min : int, max : int) -> int #must
	#no_context
{
	a += min;
	a %= (max - min);
	if a < 0 then a += (max - min);
	a -= min;

	return a;
}

wrap :: inline (a : int, max : int) -> int #must
	#no_context
{
	a %= max;
	if a < 0 then a += max;

	return a;
}

wrap :: inline (a : f32, max : f32) -> f32 #must
	#no_context
{
	a = fmod (a, max);
	if a < 0 then a += max;

	return a;
}

wrap :: inline (a : f32, min : f32, max : f32) -> f32 #must
	#no_context
{
	a += min;
	a = fmod (a, (max - min));
	if a < 0 then a += (max - min);
	a -= min;

	return a;
}

wrap :: inline (a : f64, max : f64) -> f64 #must
	#no_context
{
	a = fmod (a, max);
	if a < 0 then a += max;

	return a;
}

wrap :: inline (a : f64, min : f64, max : f64) -> f64 #must
	#no_context
{
	a += min;
	a = fmod (a, (max - min));
	if a < 0 then a += (max - min);
	a -= min;

	return a;
}

range_map :: inline (value : f32, low : f32, high : f32, mapped_low : f32, mapped_high : f32) -> f32 #must
	#no_context
{
	value -= low;
	value /= high - low;
	value *= mapped_high - mapped_low;
	value += mapped_low;

	return value;
}

range_map :: inline (value : f32, mapped_low : f32, mapped_high : f32) -> f32 #must
	#no_context
{
	return range_map (value, 0, 1, mapped_low, mapped_high);
}

range_map :: inline (value : f64, low : f64, high : f64, mapped_low : f64, mapped_high : f64) -> f64 #must
	#no_context
{
	value -= low;
	value /= high - low;
	value *= mapped_high - mapped_low;
	value += mapped_low;

	return value;
}

range_map :: inline (value : f64, mapped_low : f64, mapped_high : f64) -> f64 #must
	#no_context
{
	return range_map (value, 0, 1, mapped_low, mapped_high);
}

snap_down :: inline (value : f32, grid_size : f32) -> f32 #must
	#no_context
{
	return floor (value / grid_size) * grid_size;
}

snap :: inline (value : f32, grid_size : f32) -> f32 #must
	#no_context
{
	return round (value / grid_size) * grid_size;
}

snap_up :: inline (value : f32, grid_size : f32) -> f32 #must
	#no_context
{
	return ceil (value / grid_size) * grid_size;
}

to_rads :: inline (angle_in_degrees : $T) -> T #must
	#no_context
{
	return angle_in_degrees * PI / 180.0;
}

to_degs :: inline (angle_in_radians : $T) -> T #must
	#no_context
{
	return angle_in_radians * 180.0 / PI;
}

linear_interpolate :: inline (x : $T, y : T, t : T) -> T #must
	#no_context
{
	return x + t * (y - x);
}

lerp :: linear_interpolate;

lerp_angle :: inline (x : $T, y : T, t : T) -> T #must
	#no_context
{
	return wrap (lerp (x, y, t), 0, 2 * PI);
}

cosine_interpolate :: inline (x : $T, y : T, t : T) -> T #must
	#no_context
{
	t = (1 - cos (t * PI)) / 2;

	return inline lerp (x, y, t);
}

clerp :: cosine_interpolate;

smoothstep :: inline (x : $T, y : T, t : T) -> T #must
	#no_context
{
	t = clamp ((t - x) / (y - x), 0, 1);

	return t * t * (3 - 2 * t);
}
