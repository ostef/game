Vec2 :: struct (T : Type)
{
	x, y : T;

	#place x;
	w, h : T;

	#place x;
	width, height : T;

	#place x;
	n : [2]T;
}

Vec2f :: Vec2 (f32);
Vec2i :: Vec2 (s32);

VEC2F_ZERO :: Vec2f.{ 0, 0 };
VEC2F_ONE  :: Vec2f.{ 1, 1 };

vec2 :: inline (x : $T, y : T) -> Vec2 (T) #must
{
	result : Vec2 (T) = ---;
	result.x = x;
	result.y = y;

	return result;
}

vec2f :: #bake_constants vec2 (T = f32);
vec2i :: #bake_constants vec2 (T = s32);

scale :: inline (left : $V/Vec2, right : V) -> V #must
{
	result : V = ---;
	result.x = left.x * right.x;
	result.y = left.y * right.y;

	return result;
}

dot :: inline (left : $V/Vec2, right : V) -> V.T #must
{
	return left.x * right.x + left.y * right.y;
}

length :: inline (vec : $V/Vec2) -> f32 #must
{
	return sqrt (dot (vec, vec));
}

normalized :: inline (vec : $V/Vec2, fallback : V = .{ 0, 0 }) -> V #must, len : f32
{
	if vec.x == 0 && vec.y == 0
		return fallback, 0;
	len := length (vec);

	return vec / len, len;
}

clamp :: inline (vec : $V/Vec2, min : V, max : V) -> V #must
{
	return vec2 (clamp (vec.x, min.x, max.x), clamp (vec.y, min.y, max.y));
}

round :: inline (vec : $V/Vec2) -> V #must
{
	return vec2 (round (vec.x), round (vec.y));
}

floor :: inline (vec : $V/Vec2) -> V #must
{
	return vec2 (floor (vec.x), floor (vec.y));
}

ceil :: inline (vec : $V/Vec2f) -> V #must
{
	return vec2 (ceil (vec.x), ceil (vec.y));
}

min :: inline (a : $V/Vec2, b : V) -> V #must
{
	return vec2f (min (a.x, b.x), min (a.y, b.y));
}

max :: inline (a : $V/Vec2, b : V) -> V #must
{
	return vec2f (max (a.x, b.x), max (a.y, b.y));
}

lerp :: inline (x : $V/Vec2, y : V, t : f32) -> V #must
{
	result : V = ---;
	result.x = lerp (x.x, y.x, t);
	result.y = lerp (x.y, y.y, t);

	return result;
}

distance :: inline (a : $V/Vec2, b : V) -> f32 #must
{
	return length (b - a);
}

reflect :: inline (incident : $V/Vec2, normal : V) -> V #must
{
	return incident - 2 * dot (normal, incident) * normal;
}

project :: inline (left : $V/Vec2, right : V) -> V #must
{
	return right * (dot (left, right) / dot (right, right));
}

reject :: inline (left : $V/Vec2, right : V) -> V #must
{
	return left - right * (dot (left, right) / dot (right, right));
}

angle :: inline (a : $V/Vec2, b : V) -> f32 #must
{
	denominator := sqrt (dot (a, a) * dot (b, b));
	if approx_zero (denominator)
		return 0;
	d := clamp (dot (a, b) / denominator, -1, 1);

	return acos (d);
}

signed_angle :: inline (a : $V/Vec2, b : V) -> f32 #must
{
	s := sign (a.x * b.y - a.y * b.y);

	return angle (a, b) * s;
}

perpendicular_cw :: inline (vec : $V/Vec2) -> V #must
{
	return vec2f (vec.y, -vec.x);
}

perpendicular_ccw :: inline (vec : $V/Vec2) -> V #must
{
	return vec2f (-vec.y, vec.x);
}

add :: inline (left : $V/Vec2, right : V) -> V #must
{
	result : V = ---;
	result.x = left.x + right.x;
	result.y = left.y + right.y;

	return result;
}

sub :: inline (left : $V/Vec2, right : V) -> V #must
{
	result : V = ---;
	result.x = left.x - right.x;
	result.y = left.y - right.y;

	return result;
}

neg :: inline (vec : $V/Vec2) -> Vec2 #must
{
	result : V = ---;
	result.x = -vec.x;
	result.y = -vec.y;

	return result;
}

mul :: inline (left : $V/Vec2, right : f32) -> V #must
{
	result : V = ---;
	result.x = cast (V.T) (left.x * right);
	result.y = cast (V.T) (left.y * right);

	return result;
}

div :: inline (left : $V/Vec2, right : f32) -> V #must
{
	result : V = ---;
	result.x = cast (V.T) (left.x / right);
	result.y = cast (V.T) (left.y / right);

	return result;
}

equals :: inline (left : $V/Vec2, right : V) -> bool #must
{
	return left.x == right.x && left.y == right.y;
}

approx_zero :: inline (val : Vec2f, epsilon := F32_EPSILON) -> bool #must
{
	return approx_zero (val.x, epsilon) && approx_zero (val.y, epsilon);
}

approx_equals :: inline (left : Vec2f, right : Vec2f, epsilon := F32_EPSILON) -> bool #must
{
	return approx_equals (left.x, right.x, epsilon) && approx_equals (left.y, right.y, epsilon);
}

operator [] :: inline (vec : *$V/Vec2, index : s64) -> V.T #must
{
	return vec.n[index];
}

operator + :: inline (left : $V/Vec2, right : V) -> V #must
{
	return add (left, right);
}

operator - :: inline (left : $V/Vec2, right : V) -> V #must
{
	return sub (left, right);
}

operator - :: inline (vec : $V/Vec2) -> V #must
{
	return neg (vec);
}

operator * :: inline (left : $V/Vec2, right : f32) -> V #must
	#symmetric
{
	return mul (left, right);
}

operator / :: inline (left : $V/Vec2, right : f32) -> V #must
{
	return div (left, right);
}

operator == :: inline (left : $V/Vec2, right : V) -> bool #must
{
	return equals (left, right);
}

operator != :: inline (left : $V/Vec2, right : V) -> bool #must
{
	return !equals (left, right);
}

Vec3f :: struct
{
	x, y, z : f32;

	#place x;
	r, g, b : f32;

	#place x;
	pitch, yaw, roll : f32;

	#place x;
	xy : Vec2f;

	#place y;
	yz : Vec2f;

	#place x;
	n : [3]f32;
}

Euler_Angles :: Vec3f;

VEC3F_ZERO :: Vec3f.{ 0, 0, 0 };
VEC3F_ONE  :: Vec3f.{ 1, 1, 1 };

RIGHT_VECTOR   :: Vec3f.{ 1, 0, 0 };
UP_VECTOR      :: Vec3f.{ 0, 1, 0 };
FORWARD_VECTOR :: Vec3f.{ 0, 0, 1 };

vec3f :: inline (x : f32, y : f32, z : f32) -> Vec3f #must
{
	result : Vec3f = ---;
	result.x = x;
	result.y = y;
	result.z = z;

	return result;
}

vec3f :: inline (vec : Vec4f) -> Vec3f #must
{
	return vec.xyz;
}

euler :: inline (yaw : f32, pitch : f32, roll : f32) -> Euler_Angles #must
{
	result : Euler_Angles = ---;
	result.yaw = yaw;
	result.pitch = pitch;
	result.roll = roll;

	return result;
}

scale :: inline (left : Vec3f, right : Vec3f) -> Vec3f #must
{
	result : Vec3f = ---;
	result.x = left.x * right.x;
	result.y = left.y * right.y;
	result.z = left.z * right.z;

	return result;
}

dot :: inline (left : Vec3f, right : Vec3f) -> f32 #must
{
	return left.x * right.x + left.y * right.y + left.z * right.z;
}

length :: inline (vec : Vec3f) -> f32 #must
{
	return sqrt (dot (vec, vec));
}

normalized :: inline (vec : Vec3f, fallback := VEC3F_ZERO) -> Vec3f #must, len : f32
{
	if vec.x == 0 && vec.y == 0 && vec.z == 0
		return fallback, 0;
	len := length (vec);

	return vec / len, len;
}

clamp :: inline (vec : Vec3f, min : Vec3f, max : Vec3f) -> Vec3f #must
{
	return vec3f (clamp (vec.x, min.x, max.x), clamp (vec.y, min.y, max.y), clamp (vec.z, min.z, max.z));
}

round :: inline (vec : Vec3f) -> Vec3f #must
{
	return vec3f (round (vec.x), round (vec.y), round (vec.z));
}

floor :: inline (vec : Vec3f) -> Vec3f #must
{
	return vec3f (floor (vec.x), floor (vec.y), floor (vec.z));
}

ceil :: inline (vec : Vec3f) -> Vec3f #must
{
	return vec3f (ceil (vec.x), ceil (vec.y), ceil (vec.z));
}

min :: inline (a : Vec3f, b : Vec3f) -> Vec3f #must
{
	return vec3f (min (a.x, b.x), min (a.y, b.y), min (a.z, a.z));
}

max :: inline (a : Vec3f, b : Vec3f) -> Vec3f #must
{
	return vec3f (max (a.x, b.x), max (a.y, b.y), max (a.z, b.z));
}

lerp :: inline (x : Vec3f, y : Vec3f, t : f32) -> Vec3f #must
{
	return x + (t * (y - x));
}

distance :: inline (a : Vec3f, b : Vec3f) -> f32 #must
{
	return length (b - a);
}

reflect :: inline (incident : Vec3f, normal : Vec3f) -> Vec3f #must
{
	return incident - 2 * dot (normal, incident) * normal;
}

project :: inline (left : Vec3f, right : Vec3f) -> Vec3f #must
{
	return right * (dot (left, right) / dot (right, right));
}

reject :: inline (left : Vec3f, right : Vec3f) -> Vec3f #must
{
	return left - right * (dot (left, right) / dot (right, right));
}

// Left handed
right_to_arbitrary_up_forward :: inline (right : Vec3f, up_base := UP_VECTOR, forward_base := FORWARD_VECTOR) -> up : Vec3f, forward : Vec3f
{
	up := cross (forward_base, right);
	forward : Vec3f = ---;
	if approx_zero (length (up), 0.000001)
	{
		forward = cross (right, up_base);
		up = cross (forward, right);
	}
	else
		forward = cross (right, up);

	return normalized (up), normalized (forward);
}

// Left handed
up_to_arbitrary_right_forward :: inline (up : Vec3f, right_base := RIGHT_VECTOR, forward_base := FORWARD_VECTOR) -> right : Vec3f, forward : Vec3f
{
	right := cross (up, forward_base);
	forward : Vec3f = ---;
	if approx_zero (length (right), 0.000001)
	{
		forward = cross (right_base, up);
		right = cross (up, forward);
	}
	else
		forward = cross (right, up);

	return normalized (right), normalized (forward);
}

// Left handed
forward_to_arbitrary_right_up :: inline (forward : Vec3f, right_base := RIGHT_VECTOR, up_base := FORWARD_VECTOR) -> right : Vec3f, up : Vec3f
{
	right := cross (up_base, forward);
	up : Vec3f = ---;
	if approx_zero (length (right), 0.000001)
	{
		up = cross (forward, right_base);
		right = cross (up, forward);
	}
	else
		up = cross (forward, right);

	return normalized (right), normalized (up);
}

angle :: inline (a : Vec3f, b : Vec3f) -> f32 #must
{
	denominator := sqrt (dot (a, a) * dot (b, b));
	if approx_zero (denominator)
		return 0;
	d := clamp (dot (a, b) / denominator, -1, 1);

	return acos (d);
}

signed_angle :: inline (a : Vec3f, b : Vec3f, axis : Vec3f) -> f32 #must
{
	c := cross (a, b);
	s := sign (dot (axis, c));

	return angle (a, b) * s;
}

cross :: inline (left : Vec3f, right : Vec3f) -> Vec3f #must
{
	result : Vec3f = ---;
	result.x = left.y * right.z - left.z * right.y;
	result.y = left.z * right.x - left.x * right.z;
	result.z = left.x * right.y - left.y * right.x;

	return result;
}

add :: inline (left : Vec3f, right : Vec3f) -> Vec3f #must
{
	result : Vec3f = ---;
	result.x = left.x + right.x;
	result.y = left.y + right.y;
	result.z = left.z + right.z;

	return result;
}

sub :: inline (left : Vec3f, right : Vec3f) -> Vec3f #must
{
	result : Vec3f = ---;
	result.x = left.x - right.x;
	result.y = left.y - right.y;
	result.z = left.z - right.z;

	return result;
}

neg :: inline (vec : Vec3f) -> Vec3f #must
{
	result : Vec3f = ---;
	result.x = -vec.x;
	result.y = -vec.y;
	result.z = -vec.z;

	return result;
}

mul :: inline (left : Vec3f, right : f32) -> Vec3f #must
{
	result : Vec3f = ---;
	result.x = left.x * right;
	result.y = left.y * right;
	result.z = left.z * right;

	return result;
}

div :: inline (left : Vec3f, right : f32) -> Vec3f #must
{
	result : Vec3f = ---;
	result.x = left.x / right;
	result.y = left.y / right;
	result.z = left.z / right;

	return result;
}

equals :: inline (left : Vec3f, right : Vec3f) -> bool #must
{
	return left.x == right.x && left.y == right.y && left.z == right.z;
}

approx_zero :: inline (val : Vec3f, epsilon := F32_EPSILON) -> bool #must
{
	return approx_zero (val.x, epsilon) && approx_zero (val.y, epsilon) && approx_zero (val.z, epsilon);
}

approx_equals :: inline (left : Vec3f, right : Vec3f, epsilon := F32_EPSILON) -> bool #must
{
	return approx_equals (left.x, right.x, epsilon) && approx_equals (left.y, right.y, epsilon) && approx_equals (left.z, right.z, epsilon);
}

operator [] :: inline (vec : *Vec3f, index : s64) -> f32 #must
{
	return vec.n[index];
}

operator + :: inline (left : Vec3f, right : Vec3f) -> Vec3f #must
{
	return add (left, right);
}

operator - :: inline (left : Vec3f, right : Vec3f) -> Vec3f #must
{
	return sub (left, right);
}

operator - :: inline (vec : Vec3f) -> Vec3f #must
{
	return neg (vec);
}

operator * :: inline (left : Vec3f, right : f32) -> Vec3f #must
	#symmetric
{
	return mul (left, right);
}

operator / :: inline (left : Vec3f, right : f32) -> Vec3f #must
{
	return div (left, right);
}

operator == :: inline (left : Vec3f, right : Vec3f) -> bool #must
{
	return equals (left, right);
}

operator != :: inline (left : Vec3f, right : Vec3f) -> bool #must
{
	return !equals (left, right);
}

Vec4f :: struct
{
	x, y, z, w : f32;

	#place x;
	r, g, b, a : f32;

	#place r;
	rgb : Vec3f;

	#place x;
	xy : Vec2f;

	#place x;
	xyz : Vec3f;

	#place y;
	yz : Vec2f;

	#place y;
	yzw : Vec3f;

	#place z;
	zw : Vec2f;

	#place x;
	n : [4]f32;
}

VEC4F_ZERO :: Vec4f.{ 0, 0, 0, 0 };
VEC4F_ONE  :: Vec4f.{ 1, 1, 1, 1 };

vec4f :: inline (x : f32, y : f32, z : f32, w : f32) -> Vec4f #must
{
	result : Vec4f = ---;
	result.x = x;
	result.y = y;
	result.z = z;
	result.w = w;

	return result;
}

vec4f :: inline (xyz : Vec3f, w := 0.0) -> Vec4f #must
{
	result : Vec4f = ---;
	result.xyz = xyz;
	result.w = w;

	return result;
}

scale :: inline (left : Vec4f, right : Vec4f) -> Vec4f #must
{
	result : Vec4f = ---;
	result.x = left.x * right.x;
	result.y = left.y * right.y;
	result.z = left.z * right.z;
	result.w = left.w * right.w;

	return result;
}

dot :: inline (left : Vec4f, right : Vec4f) -> f32 #must
{
	return left.x * right.x + left.y * right.y + left.z * right.z + left.w * right.w;
}

length :: inline (vec : Vec4f) -> f32 #must
{
	return sqrt (dot (vec, vec));
}

normalized :: inline (vec : Vec4f, fallback := VEC4F_ZERO) -> Vec4f #must, len : f32
{
	if vec.x == 0 && vec.y == 0 && vec.z == 0 && vec.w == 0
		return fallback, 0;
	len := length (vec);

	return vec / len, len;
}

clamp :: inline (vec : Vec4f, min : Vec4f, max : Vec4f) -> Vec4f #must
{
	return vec4f (
		clamp (vec.x, min.x, max.x),
		clamp (vec.y, min.y, max.y),
		clamp (vec.z, min.z, max.z),
		clamp (vec.w, min.w, max.w)
	);
}

round :: inline (vec : Vec4f) -> Vec4f #must
{
	return vec4f (round (vec.x), round (vec.y), round (vec.z), round (vec.w));
}

floor :: inline (vec : Vec4f) -> Vec4f #must
{
	return vec4f (floor (vec.x), floor (vec.y), floor (vec.z), floor (vec.w));
}

ceil :: inline (vec : Vec4f) -> Vec4f #must
{
	return vec4f (ceil (vec.x), ceil (vec.y), ceil (vec.z), ceil (vec.w));
}

min :: inline (a : Vec4f, b : Vec4f) -> Vec4f #must
{
	return vec4f (min (a.x, b.x), min (a.y, b.y), min (a.z, b.z), min (a.w, a.w));
}

max :: inline (a : Vec4f, b : Vec4f) -> Vec4f #must
{
	return vec4f (max (a.x, b.x), max (a.y, b.y), max (a.z, b.z), max (a.w, b.w));
}

lerp :: inline (x : Vec4f, y : Vec4f, t : f32) -> Vec4f #must
{
	return x + (t * (y - x));
}

distance :: inline (a : Vec4f, b : Vec4f) -> f32 #must
{
	return length (b - a);
}

reflect :: inline (incident : Vec4f, normal : Vec4f) -> Vec4f #must
{
	return incident - 2 * dot (normal, incident) * normal;
}

project :: inline (left : Vec4f, right : Vec4f) -> Vec4f #must
{
	return right * (dot (left, right) / dot (right, right));
}

reject :: inline (left : Vec4f, right : Vec4f) -> Vec4f #must
{
	return left - right * (dot (left, right) / dot (right, right));
}

add :: inline (left : Vec4f, right : Vec4f) -> Vec4f #must
{
	result : Vec4f = ---;
	result.x = left.x + right.x;
	result.y = left.y + right.y;
	result.z = left.z + right.z;
	result.w = left.w + right.w;

	return result;
}

sub :: inline (left : Vec4f, right : Vec4f) -> Vec4f #must
{
	result : Vec4f = ---;
	result.x = left.x - right.x;
	result.y = left.y - right.y;
	result.z = left.z - right.z;
	result.w = left.w - right.w;

	return result;
}

neg :: inline (vec : Vec4f) -> Vec4f #must
{
	result : Vec4f = ---;
	result.x = -vec.x;
	result.y = -vec.y;
	result.z = -vec.z;
	result.w = -vec.w;

	return result;
}

mul :: inline (left : Vec4f, right : f32) -> Vec4f #must
{
	result : Vec4f = ---;
	result.x = left.x * right;
	result.y = left.y * right;
	result.z = left.z * right;
	result.w = left.w * right;

	return result;
}

div :: inline (left : Vec4f, right : f32) -> Vec4f #must
{
	result : Vec4f = ---;
	result.x = left.x / right;
	result.y = left.y / right;
	result.z = left.z / right;
	result.w = left.w / right;

	return result;
}

equals :: inline (left : Vec4f, right : Vec4f) -> bool #must
{
	return left.x == right.x && left.y == right.y && left.z == right.z && left.w == right.w;
}

approx_zero :: inline (val : Vec4f, epsilon := F32_EPSILON) -> bool #must
{
	return approx_zero (val.x, epsilon) && approx_zero (val.y, epsilon) && approx_zero (val.z, epsilon) && approx_zero (val.w, epsilon);
}

approx_equals :: inline (left : Vec4f, right : Vec4f, epsilon := F32_EPSILON) -> bool #must
{
	return approx_equals (left.x, right.x, epsilon) && approx_equals (left.y, right.y, epsilon) && approx_equals (left.z, right.z, epsilon) && approx_equals (left.w, right.w, epsilon);
}

operator [] :: inline (vec : *Vec4f, index : s64) -> f32 #must
{
	return vec.n[index];
}

operator + :: inline (left : Vec4f, right : Vec4f) -> Vec4f #must
{
	return add (left, right);
}

operator - :: inline (left : Vec4f, right : Vec4f) -> Vec4f #must
{
	return sub (left, right);
}

operator - :: inline (vec : Vec4f) -> Vec4f #must
{
	return neg (vec);
}

operator * :: inline (left : Vec4f, right : f32) -> Vec4f #must
	#symmetric
{
	return mul (left, right);
}

operator / :: inline (left : Vec4f, right : f32) -> Vec4f #must
{
	return div (left, right);
}

operator == :: inline (left : Vec4f, right : Vec4f) -> bool #must
{
	return equals (left, right);
}

operator != :: inline (left : Vec4f, right : Vec4f) -> bool #must
{
	return !equals (left, right);
}
