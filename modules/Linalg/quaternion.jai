Quatf :: struct
{
	x, y, z, w : f32;

	#place x;
	as_vec4f : Vec4f;

	#place x;
	vec : Vec3f;
	scalar : f32;

	#place x;
	n : [4]f32;
}

QUATF_ZERO :: Quatf.{ 0, 0, 0, 0 };
QUATF_IDENTITY :: Quatf.{ 0, 0, 0, 1 };

quatf :: inline (x : f32, y : f32, z : f32, w : f32) -> Quatf #must
{
	result : Quatf = ---;
	result.x = x;
	result.y = y;
	result.z = z;
	result.w = w;

	return result;
}

quatf :: inline (vec : Vec3f, scalar : f32) -> Quatf #must
{
	result : Quatf = ---;
	result.vec = vec;
	result.scalar = scalar;

	return result;
}

quatf_look_at :: inline (forward : Vec3f, up := UP_VECTOR) -> Quatf #must
{
	f := normalized (forward, FORWARD_VECTOR);
	u := normalized (up, UP_VECTOR);
	d := dot (FORWARD_VECTOR, f);
	if approx_equals (d, -1)
		return quatf_axis_angle (u, PI);
	else if approx_equals (d, 1)
		return QUATF_IDENTITY;
	angle := acos (d);
	axis  := cross (FORWARD_VECTOR, f);
	axis   = normalized (axis);

	return quatf_axis_angle (axis, angle, ensure_normalized = false);
}

quatf_axis_angle :: inline (axis : Vec3f, angle : f32, $ensure_normalized := true) -> Quatf #must
{
#if ensure_normalized
	a := normalized (axis);
else
	a := axis;
	c := cos (angle / 2.0);
	s := sin (angle / 2.0);

	return quatf (a.x * s, a.y * s, a.z * s, c);
}

quatf_euler_angles :: inline (euler : Vec3f) -> Quatf #must
{
	yaw   := quatf_axis_angle (UP_VECTOR,      euler.yaw,   ensure_normalized = false);
	pitch := quatf_axis_angle (RIGHT_VECTOR,   euler.pitch, ensure_normalized = false);
	roll  := quatf_axis_angle (FORWARD_VECTOR, euler.roll,  ensure_normalized = false);

	return roll * yaw * pitch;
}

to_euler_angles :: inline (quat : Quatf) -> Vec3f #must
{
	result : Vec3f = ---;

	// Yaw
	siny_cosp :=     2 * (quat.w * quat.y + quat.z * quat.x);
	cosy_cosp := 1 - 2 * (quat.x * quat.x + quat.y * quat.y);
	result.yaw = atan2 (siny_cosp, cosy_cosp);

	// Pitch
	sinp := 2 * (quat.w * quat.x - quat.y * quat.z);
	     if sinp >=  1 then result.pitch =  PI / 2; 
	else if sinp <= -1 then result.pitch = -PI / 2;
	else                    result.pitch = asin (sinp); 

	// Roll
	sinr_cosp :=     2 * (quat.w * quat.z + quat.x * quat.y);
	cosr_cosp := 1 - 2 * (quat.z * quat.z + quat.x * quat.x);
	result.roll = atan2 (sinr_cosp, cosr_cosp);

	return result;
}

dot :: inline (left : Quatf, right : Quatf) -> f32 #must
{
	return left.x * right.x + left.y * right.y + left.z * right.z + left.w * right.w;
}

length :: inline (quat : Quatf) -> f32 #must
{
	return sqrt (dot (quat, quat));
}

normalized :: inline (quat : Quatf, fallback := QUATF_IDENTITY) -> Quatf #must, len : f32
{
	if quat.x == 0 && quat.y == 0 && quat.z == 0 && quat.w == 0
		return fallback, 0;
	len := length (quat);

	return quat / len, len;
}

inverse :: inline (quat : Quatf) -> Quatf #must
{
	sqrd_length := dot (quat, quat);
	if sqrd_length == 0.0
		return quat;

	return quatf (-quat.x, -quat.y, -quat.z, quat.w) / sqrd_length;
}

conjugate :: inline (quat : Quatf) -> Quatf #must
{
	return quatf (-quat.x, -quat.y, -quat.z, quat.w);
}

angle :: inline (quat : Quatf) -> f32 #must
{
	return acos (quat.w) * 2;
}

angle :: inline (a : Quatf, b : Quatf) -> f32 #must
{
	return angle (b * inverse (a));
}

to_axis_angle :: inline (quat : Quatf, fallback_axis := FORWARD_VECTOR) -> Vec3f, f32
{
	w     := clamp (quat.w, -1, 1);
	theta := acos (w);
	sint  := sin (theta);
	theta *= 2;
	if approx_zero (sint)
		return fallback_axis, theta;

	return vec3f (quat.x / sint, quat.y / sint, quat.z / sint), theta;
}

to_matrix :: inline (quat : Quatf) -> Mat4f #must
{
	x_x := quat.x * quat.x;
	y_y := quat.y * quat.y;
	z_z := quat.z * quat.z;
	x_y := quat.x * quat.y;
	x_z := quat.x * quat.z;
	y_z := quat.y * quat.z;
	w_x := quat.w * quat.x;
	w_y := quat.w * quat.y;
	w_z := quat.w * quat.z;

	return mat4f (
		1 - 2 * (y_y + z_z),     2 * (x_y - w_z),     2 * (x_z + w_y), 0,
		    2 * (x_y + w_z), 1 - 2 * (x_x + z_z),     2 * (y_z - w_x), 0,
		    2 * (x_z - w_y),     2 * (y_z + w_x), 1 - 2 * (x_x + y_y), 0,
		                  0,                    0,                  0, 1
	);
}

// Here's one place where /interface is useful: we often use 3x3 matrices
// to represent rotation, so we might want to convert from Mat3f to Quatf.
// But we also often want to extract the rotation of a transform matrix,
// which is a Mat4f. Since Mat4f has all the members of Mat3f, we can pass
// a Mat4f here, and there is not duplicated code!
// Actually, we can't use /interface, because the rows members are Vec3fs
// in Mat3f, and they are Vec4fs in Mat4f.
to_quaternion :: inline (mat : $T/*/interface Mat3f*/) -> Quatf #must
{
	result : Quatf = ---;
	t : f32 = ---;
	
	if mat.r2c2 < 0
	{
		if mat.r0c0 > mat.r1c1
		{
			t = 1 + mat.r0c0 - mat.r1c1 - mat.r2c2;
			result = quatf (t, mat.r1c0 + mat.r0c1, mat.r0c2 + mat.r2c0, mat.r2c1 - mat.r1c2);
		}
		else
		{
			t = 1 - mat.r0c0 + mat.r1c1 - mat.r2c2;
			result = quatf (mat.r1c0 + mat.r0c1, t, mat.r1c2 + mat.r2c1, mat.r2c0 - mat.r0c2);
		}
	}
	else
	{
		if mat.r0c0 < -mat.r1c1
		{
			t = 1 - mat.r0c0 - mat.r1c1 + mat.r2c2;
			result = quatf (mat.r0c2 + mat.r2c0, mat.r2c1 + mat.r1c2, t, mat.r1c0 - mat.r0c1);
		}
		else
		{
			t = 1 + mat.r0c0 + mat.r1c1 + mat.r2c2;
			result = quatf (mat.r2c1 - mat.r1c2, mat.r0c2 - mat.r2c0, mat.r1c0 - mat.r0c1, t);
		}
	}

	return result * 0.5 / sqrt (t);
}

rotate_vector :: inline (vec : Vec3f, quat : Quatf) -> Vec3f #must
{
	return (quat * quatf (vec, 0) * inverse (quat)).vec;
}

right_vector :: inline (quat : Quatf) -> Vec3f #must
{
	return rotate_vector (RIGHT_VECTOR, quat);
}

up_vector :: inline (quat : Quatf) -> Vec3f #must
{
	return rotate_vector (UP_VECTOR, quat);
}

forward_vector :: inline (quat : Quatf) -> Vec3f #must
{
	return rotate_vector (FORWARD_VECTOR, quat);
}

nlerp :: inline (a : Quatf, b : Quatf, t : f32, $shortest_path := true) -> Quatf #must
{
	first  := a;
	second := b;
#if shortest_path
{
	if dot (first, second) < 0 then second = -second;
}

	return normalized ((1 - t) * first + t * second);
}

add :: inline (left : Quatf, right : Quatf) -> Quatf #must
{
	result : Quatf = ---;
	result.x = left.x + right.x;
	result.y = left.y + right.y;
	result.z = left.z + right.z;
	result.w = left.w + right.w;

	return result;
}

sub :: inline (left : Quatf, right : Quatf) -> Quatf #must
{
	result : Quatf = ---;
	result.x = left.x - right.x;
	result.y = left.y - right.y;
	result.z = left.z - right.z;
	result.w = left.w - right.w;

	return result;
}

neg :: inline (vec : Quatf) -> Quatf #must
{
	result : Quatf = ---;
	result.x = -vec.x;
	result.y = -vec.y;
	result.z = -vec.z;
	result.w = -vec.w;

	return result;
}

mul :: inline (left : Quatf, right : f32) -> Quatf #must
{
	result : Quatf = ---;
	result.x = left.x * right;
	result.y = left.y * right;
	result.z = left.z * right;
	result.w = left.w * right;

	return result;
}

mul :: inline (left : Quatf, right : Quatf) -> Quatf #must
{
	w1 := left.w;
	x1 := left.x;
	y1 := left.y;
	z1 := left.z;

	w2 := right.w;
	x2 := right.x;
	y2 := right.y;
	z2 := right.z;

	result : Quatf = ---;
	result.x = w1 * x2 + x1 * w2 + y1 * z2 - z1 * y2;
	result.y = w1 * y2 - x1 * z2 + w2 * y1 + z1 * x2;
	result.z = w1 * z2 + x1 * y2 - y1 * x2 + w2 * z1;
	result.w = w1 * w2 - x1 * x2 - y1 * y2 - z1 * z2;

	return result;
}

div :: inline (left : Quatf, right : f32) -> Quatf #must
{
	result : Quatf = ---;
	result.x = left.x / right;
	result.y = left.y / right;
	result.z = left.z / right;
	result.w = left.w / right;

	return result;
}

equals :: inline (left : Quatf, right : Quatf) -> bool #must
{
	return left.x == right.x && left.y == right.y && left.z == right.z && left.w == right.w;
}

approx_zero :: inline (val : Quatf, epsilon := F32_EPSILON) -> bool #must
{
	return approx_zero (val.x, epsilon) && approx_zero (val.y, epsilon) && approx_zero (val.z, epsilon) && approx_zero (val.w, epsilon);
}

approx_equals :: inline (left : Quatf, right : Quatf, epsilon := F32_EPSILON) -> bool #must
{
	return approx_equals (left.x, right.x, epsilon) && approx_equals (left.y, right.y, epsilon) && approx_equals (left.z, right.z, epsilon) && approx_equals (left.w, right.w, epsilon);
}

operator [] :: inline (vec : *Quatf, index : s64) -> f32 #must
{
	return vec.n[index];
}

operator + :: inline (left : Quatf, right : Quatf) -> Quatf #must
{
	return add (left, right);
}

operator - :: inline (left : Quatf, right : Quatf) -> Quatf #must
{
	return sub (left, right);
}

operator - :: inline (vec : Quatf) -> Quatf #must
{
	return neg (vec);
}

operator * :: inline (left : Quatf, right : f32) -> Quatf #must
	#symmetric
{
	return mul (left, right);
}

operator * :: inline (left : Quatf, right : Quatf) -> Quatf #must
{
	return mul (left, right);
}

operator / :: inline (left : Quatf, right : f32) -> Quatf #must
{
	return div (left, right);
}

operator == :: inline (left : Quatf, right : Quatf) -> bool #must
{
	return equals (left, right);
}

operator != :: inline (left : Quatf, right : Quatf) -> bool #must
{
	return !equals (left, right);
}
