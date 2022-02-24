Mat3f :: struct
{
	r0c0 : f32; r0c1 : f32; r0c2 : f32; @Fmt_Newline
	r1c0 : f32; r1c1 : f32; r1c2 : f32; @Fmt_Newline
	r2c0 : f32; r2c1 : f32; r2c2 : f32; @Fmt_Newline

	#place r0c0;
	c0r0, c1r0, c2r0 : f32;
	c0r1, c1r1, c2r1 : f32;
	c0r2, c1r2, c2r2 : f32;

	#place r0c0;
	rows : [3]Vec3f;

	#place r0c0;
	r0 : Vec3f;
	r1 : Vec3f;
	r2 : Vec3f;

	#place r0c0;
	n : [3][3]f32;
}

MAT3F_ZERO :: Mat3f.{
	0, 0, 0,
	0, 0, 0,
	0, 0, 0
};

MAT3F_IDENTITY :: Mat3f.{
	1, 0, 0,
	0, 1, 0,
	0, 0, 1
};

mat3f :: inline (
	r0c0 : f32, r0c1 : f32, r0c2 : f32,
	r1c0 : f32, r1c1 : f32, r1c2 : f32,
	r2c0 : f32, r2c1 : f32, r2c2 : f32
) -> Mat3f #must
{
	result : Mat3f = ---;
	result.r0c0 = r0c0;
	result.r0c1 = r0c1;
	result.r0c2 = r0c2;

	result.r1c0 = r1c0;
	result.r1c1 = r1c1;
	result.r1c2 = r1c2;

	result.r2c0 = r2c0;
	result.r2c1 = r2c1;
	result.r2c2 = r2c2;

	return result;
}

mat3f :: inline (
	r0 : Vec3f,
	r1 : Vec3f,
	r2 : Vec3f
) -> Mat3f #must
{
	result : Mat3f = ---;
	result.r0 = r0;
	result.r1 = r1;
	result.r2 = r2;

	return result;
}

mat3f_rotate :: inline (axis : Vec3f, angle : f32) -> Mat3f #must
{
	n := normalized (axis);
	s := sin (angle);
	c := cos (angle);
	c2 := 1 - c;

	result : Mat3f;
	result.r0c0 = (n.x * n.x * c2) + c;
	result.r0c1 = (n.y * n.x * c2) - (n.z * s);
	result.r0c2 = (n.z * n.x * c2) + (n.y * s);

	result.r1c0 = (n.x * n.y * c2) + (n.z * s);
	result.r1c1 = (n.y * n.y * c2) + c;
	result.r1c2 = (n.z * n.y * c2) - (n.x * s);

	result.r2c0 = (n.x * n.z * c2) - (n.y * s);
	result.r2c1 = (n.y * n.z * c2) + (n.x * s);
	result.r2c2 = (n.z * n.z * c2) + c;

	return result;
}

get_row :: inline (mat : Mat3f, index : s64) -> Vec3f #must
{
	return mat.rows[index];
}

set_row :: inline (mat : *Mat3f, index : s64, row : Vec3f)
{
	mat.rows[index] = row;
}

get_column :: inline (mat : Mat3f, index : s64) -> Vec3f #must
{
	result : Vec3f = ---;
	result.x = mat.n[0][index];
	result.y = mat.n[1][index];
	result.z = mat.n[2][index];

	return result;
}

set_column :: inline (mat : *Mat3f, index : s64, column : Vec3f)
{
	mat.n[0][index] = column.x;
	mat.n[1][index] = column.y;
	mat.n[2][index] = column.z;
}

inverse :: inline (mat : Mat3f) -> Mat3f #must
{
	panic ("TODO");
	return MAT3F_IDENTITY;
}

transposed :: inline (mat : Mat3f) -> Mat3f #must
{
	result : Mat3f = ---;
	result.r0c0 = mat.c0r0;
	result.r0c1 = mat.c0r1;
	result.r0c2 = mat.c0r2;

	result.r1c0 = mat.c1r0;
	result.r1c1 = mat.c1r1;
	result.r1c2 = mat.c1r2;

	result.r2c0 = mat.c2r0;
	result.r2c1 = mat.c2r1;
	result.r2c2 = mat.c2r2;

	return result;
}

add :: inline (left : Mat3f, right : Mat3f) -> Mat3f #must
{
	result : Mat3f = ---;
	result.r0 = left.r0 + right.r0;
	result.r1 = left.r1 + right.r1;
	result.r2 = left.r2 + right.r2;

	return result;
}

sub :: inline (left : Mat3f, right : Mat3f) -> Mat3f #must
{
	result : Mat3f = ---;
	result.r0 = left.r0 - right.r0;
	result.r1 = left.r1 - right.r1;
	result.r2 = left.r2 - right.r2;

	return result;
}

neg :: inline (mat : Mat3f) -> Mat3f #must
{
	result : Mat3f = ---;
	result.r0 = -mat.r0;
	result.r1 = -mat.r1;
	result.r2 = -mat.r2;

	return result;
}

mul :: inline (left : Mat3f, right : f32) -> Mat3f #must
{
	result : Mat3f = ---;
	result.r0 = left.r0 * right;
	result.r1 = left.r1 * right;
	result.r2 = left.r2 * right;

	return result;
}

mul :: inline (left : Mat3f, right : Vec3f) -> Vec3f #must
{
	result : Vec3f = ---;
	result.n[0] = left.n[0][0] * right.n[0] + left.n[1][0] * right.n[1] + left.n[2][0] * right.n[2];
	result.n[1] = left.n[0][1] * right.n[0] + left.n[1][1] * right.n[1] + left.n[2][1] * right.n[2];
	result.n[2] = left.n[0][2] * right.n[0] + left.n[1][2] * right.n[1] + left.n[2][2] * right.n[2];

	return result;
}

mul :: inline (left : Mat3f, right : Mat3f) -> Mat3f #must
{
	result : Mat3f = ---;
	result.r0 = left * right.r0;
	result.r1 = left * right.r1;
	result.r2 = left * right.r2;

	return result;
}

div :: inline (left : Mat3f, right : f32) -> Mat3f #must
{
	result : Mat3f = ---;
	result.r0 = left.r0 / right;
	result.r1 = left.r1 / right;
	result.r2 = left.r2 / right;

	return result;
}

equals :: inline (left : Mat3f, right : Mat3f) -> bool #must
{
	return equals (left.r0, right.r0) && equals (left.r1, right.r1) && equals (left.r2, right.r2);
}

approx_zero :: inline (mat : Mat3f, epsilon := F32_EPSILON) -> bool #must
{
	return approx_zero (mat.r0, epsilon) && approx_zero (mat.r1, epsilon) && approx_zero (mat.r2, epsilon);
}

approx_equals :: inline (left : Mat3f, right : Mat3f, epsilon := F32_EPSILON) -> bool #must
{
	return approx_equals (left.r0, right.r0, epsilon) && approx_equals (left.r1, right.r1, epsilon) && approx_equals (left.r2, right.r2, epsilon);
}

operator [] :: inline (mat : *Mat3f, row_index : s64) -> Vec3f #must
{
	return mat.rows[row_index];
}

operator + :: inline (left : Mat3f, right : Mat3f) -> Mat3f #must
{
	return add (left, right);
}

operator - :: inline (left : Mat3f, right : Mat3f) -> Mat3f #must
{
	return sub (left, right);
}

operator - :: inline (mat : Mat3f) -> Mat3f #must
{
	return neg (mat);
}

operator * :: inline (left : Mat3f, right : f32) -> Mat3f #must
	#symmetric
{
	return mul (left, right);
}

operator * :: inline (left : Mat3f, vec : Vec3f) -> Vec3f #must
{
	return mul (left, vec);
}

operator * :: inline (left : Mat3f, right : Mat3f) -> Mat3f #must
{
	return mul (left, right);
}

operator / :: inline (left : Mat3f, right : f32) -> Mat3f #must
{
	return div (left, right);
}

operator == :: inline (left : Mat3f, right : Mat3f) -> bool #must
{
	return equals (left, right);
}

operator != :: inline (left : Mat3f, right : Mat3f) -> bool #must
{
	return !equals (left, right);
}

Mat4f :: struct
{
	r0c0 : f32; r0c1 : f32; r0c2 : f32; r0c3 : f32; @Fmt_Newline
	r1c0 : f32; r1c1 : f32; r1c2 : f32; r1c3 : f32; @Fmt_Newline
	r2c0 : f32; r2c1 : f32; r2c2 : f32; r2c3 : f32; @Fmt_Newline
	r3c0 : f32; r3c1 : f32; r3c2 : f32; r3c3 : f32; @Fmt_Newline

	#place r0c0;
	c0r0, c1r0, c2r0, c3r0 : f32;
	c0r1, c1r1, c2r1, c3r1 : f32;
	c0r2, c1r2, c2r2, c3r2 : f32;
	c0r3, c1r3, c2r3, c3r3 : f32;

	#place r0c0;
	rows : [4]Vec4f;

	#place r0c0;
	r0 : Vec4f;
	r1 : Vec4f;
	r2 : Vec4f;
	r3 : Vec4f;

	#place r0c0;
	n : [4][4]f32;
}

MAT4F_ZERO :: Mat4f.{
	0, 0, 0, 0,
	0, 0, 0, 0,
	0, 0, 0, 0,
	0, 0, 0, 0
};

MAT4F_IDENTITY :: Mat4f.{
	1, 0, 0, 0,
	0, 1, 0, 0,
	0, 0, 1, 0,
	0, 0, 0, 1
};

mat4f :: inline (
	r0c0 : f32, r0c1 : f32, r0c2 : f32, r0c3 : f32,
	r1c0 : f32, r1c1 : f32, r1c2 : f32, r1c3 : f32,
	r2c0 : f32, r2c1 : f32, r2c2 : f32, r2c3 : f32,
	r3c0 : f32, r3c1 : f32, r3c2 : f32, r3c3 : f32
) -> Mat4f #must
{
	result : Mat4f = ---;
	result.r0c0 = r0c0;
	result.r0c1 = r0c1;
	result.r0c2 = r0c2;
	result.r0c3 = r0c3;

	result.r1c0 = r1c0;
	result.r1c1 = r1c1;
	result.r1c2 = r1c2;
	result.r1c3 = r1c3;

	result.r2c0 = r2c0;
	result.r2c1 = r2c1;
	result.r2c2 = r2c2;
	result.r2c3 = r2c3;

	result.r3c0 = r3c0;
	result.r3c1 = r3c1;
	result.r3c2 = r3c2;
	result.r3c3 = r3c3;

	return result;
}

mat4f :: inline (
	r0 : Vec4f,
	r1 : Vec4f,
	r2 : Vec4f,
	r3 : Vec4f
) -> Mat4f #must
{
	result : Mat4f = ---;
	result.r0 = r0;
	result.r1 = r1;
	result.r2 = r2;
	result.r3 = r3;

	return result;
}

mat4f_translate :: inline (vec : Vec3f) -> Mat4f #must
{
	return mat4f_translate (vec.x, vec.y, vec.z);
}

mat4f_translate :: inline (x : f32, y : f32, z : f32) -> Mat4f #must
{
	result := MAT4F_IDENTITY;
	result.r0c3 = x;
	result.r1c3 = y;
	result.r2c3 = z;

	return result;
}

mat4f_scale :: inline (vec : Vec3f) -> Mat4f #must
{
	return mat4f_scale (vec.x, vec.y, vec.z);
}

mat4f_scale :: inline (x : f32, y : f32, z : f32) -> Mat4f #must
{
	result := MAT4F_IDENTITY;
	result.r0c0 = x;
	result.r1c1 = y;
	result.r2c2 = z;

	return result;
}

mat4f_rotate :: mat4f_axis_angle;
mat4f_axis_angle :: inline (axis : Vec3f, angle : f32) -> Mat4f #must
{
	n := normalized (axis);
	s := sin (angle);
	c := cos (angle);
	c2 := 1 - c;

	result : Mat4f;
	result.r0c0 = (n.x * n.x * c2) + c;
	result.r0c1 = (n.y * n.x * c2) - (n.z * s);
	result.r0c2 = (n.z * n.x * c2) + (n.y * s);

	result.r1c0 = (n.x * n.y * c2) + (n.z * s);
	result.r1c1 = (n.y * n.y * c2) + c;
	result.r1c2 = (n.z * n.y * c2) - (n.x * s);

	result.r2c0 = (n.x * n.z * c2) - (n.y * s);
	result.r2c1 = (n.y * n.z * c2) + (n.x * s);
	result.r2c2 = (n.z * n.z * c2) + c;

	result.r3c3 = 1;

	return result;
}

mat4f_transform :: inline (translation : Vec3f, rotation : Quatf, scale := Vec3f.{ 1, 1, 1 }) -> Mat4f #must
{
	return mat4f_scale (scale) * to_matrix (rotation) * mat4f_translate (translation);
}

mat4f_look_at :: inline (position : Vec3f, target : Vec3f, up := UP_VECTOR) -> Mat4f #must
{
	align_z :: inline (axis : Vec3f, up : Vec3f) -> Mat4f #must
	{
		x, y : Vec3f;
		y = up - axis * dot (up, axis);
		ylen := length (y);

		if approx_zero (ylen, 0.000001)
		{
			k := RIGHT_VECTOR;
			y = k - axis * dot (k, axis);
			ylen = length (y);

			if approx_zero (ylen, 0.000001)
			{
				k := FORWARD_VECTOR;
				y = k - axis * dot (k, axis);
				ylen = length (y);
			}
		}

		y /= ylen;
		x = cross (y, axis);

		return mat4f (
			x.x, y.x, axis.x, 0,
			x.y, y.y, axis.y, 0,
			x.z, y.z, axis.z, 0,
			  0,   0,      0, 1
		);
	}

	direction := normalized (target - position, fallback = FORWARD_VECTOR);
	up_vector := normalized (up, fallback = UP_VECTOR);
	result := align_z (direction, up_vector);
	set_column (*result, 3, vec4f (position, 1));

	return result;
}

mat4f_orthographic_projection :: inline (l : f32, r : f32, b : f32, t : f32, n : f32, f : f32) -> Mat4f #must
{
	return mat4f (
		2 / (r - l),           0,           0, (r + l) / (l - r),
		          0, 2 / (t - b),           0, (t + b) / (b - t),
		          0,           0, 2 / (n / f), (n + f) / (n - f),
		          0,           0,           0,                 1
	);
}

mat4f_perspective_projection :: inline (fov_in_degrees : f32, aspect : f32, n : f32, f : f32, left_handed := true) -> Mat4f #must
{
	view_z := ifx left_handed then 1.0 else -1.0
	t := tan (to_rads (fov_in_degrees) * 0.5) * n;
	b := -t;
	r := aspect * t;
	l := -r;

	return mat4f (
		2 * n / (r - l),               0, -view_z * (r + l) / (r - l),      0,
		              0, 2 * n / (t - b), -view_z * (t + b) / (t - b),      0,
		              0,               0,                      view_z, -2 * n,
		              0,               0,                      view_z,      0
	);
}

right_vector :: inline (mat : Mat4f) -> Vec3f #must
{
	return get_column (mat, 0).xyz;
}

up_vector :: inline (mat : Mat4f) -> Vec3f #must
{
	return get_column (mat, 1).xyz;
}

forward_vector :: inline (mat : Mat4f) -> Vec3f #must
{
	return get_column (mat, 2).xyz;
}

translation_vector :: inline (mat : Mat4f) -> Vec3f #must
{
	return get_column (mat, 3).xyz;
}

scale_vector :: inline (mat : Mat4f) -> Vec3f #must
{
	result : Vec3f = ---;
	result.x = length (get_column (mat, 0));
	result.y = length (get_column (mat, 1));
	result.z = length (get_column (mat, 2));

	return result;
}

rotation_matrix :: inline (mat : Mat4f) -> Mat4f #must
{
	result : Mat4f = ---;
	set_column (*result, 0, normalized (get_column (mat, 0)));
	set_column (*result, 1, normalized (get_column (mat, 1)));
	set_column (*result, 2, normalized (get_column (mat, 2)));
	set_column (*result, 3, vec4f (0, 0, 0, 1));

	return result;
}

get_row :: inline (mat : Mat4f, index : s64) -> Vec4f #must
{
	return mat.rows[index];
}

set_row :: inline (mat : *Mat4f, index : s64, row : Vec4f)
{
	mat.rows[index] = row;
}

get_column :: inline (mat : Mat4f, index : s64) -> Vec4f #must
{
	result : Vec4f = ---;
	result.x = mat.n[0][index];
	result.y = mat.n[1][index];
	result.z = mat.n[2][index];
	result.w = mat.n[3][index];

	return result;
}

set_column :: inline (mat : *Mat4f, index : s64, column : Vec4f)
{
	mat.n[0][index] = column.x;
	mat.n[1][index] = column.y;
	mat.n[2][index] = column.z;
	mat.n[3][index] = column.w;
}

inverse :: inline (mat : Mat4f) -> Mat4f #must
{
	a := vec3f (mat.c0r0, mat.c0r1, mat.c0r2);
	b := vec3f (mat.c1r0, mat.c1r1, mat.c1r2);
	c := vec3f (mat.c2r0, mat.c2r1, mat.c2r2);
	d := vec3f (mat.c3r0, mat.c3r1, mat.c3r2);

	x := mat.r3c0;
	y := mat.r3c1;
	z := mat.r3c2;
	w := mat.r3c3;

	s := cross (a, b);
	t := cross (c, d);
	u := a * y - b * x;
	v := c * w - d * z;

	det := dot (s, v) + dot (t, u);
	s /= det;
	t /= det;
	u /= det;
	v /= det;

	row1 := cross (b, v) + t * y;
	row2 := cross (v, a) - t * x;
	row3 := cross (d, u) + s * w;
	row4 := cross (u, c) - s * z;

	return mat4f (
		vec4f (row1, -dot (b, t)),
		vec4f (row2,  dot (a, t)),
		vec4f (row3, -dot (d, s)),
		vec4f (row4,  dot (c, s))
	);
}

transposed :: inline (mat : Mat4f) -> Mat4f #must
{
	result : Mat4f = ---;
	result.r0c0 = mat.c0r0;
	result.r0c1 = mat.c0r1;
	result.r0c2 = mat.c0r2;
	result.r0c3 = mat.c0r3;

	result.r1c0 = mat.c1r0;
	result.r1c1 = mat.c1r1;
	result.r1c2 = mat.c1r2;
	result.r1c3 = mat.c1r3;

	result.r2c0 = mat.c2r0;
	result.r2c1 = mat.c2r1;
	result.r2c2 = mat.c2r2;
	result.r2c3 = mat.c2r3;

	return result;
}

add :: inline (left : Mat4f, right : Mat4f) -> Mat4f #must
{
	result : Mat4f = ---;
	result.r0 = left.r0 + right.r0;
	result.r1 = left.r1 + right.r1;
	result.r2 = left.r2 + right.r2;
	result.r3 = left.r3 + right.r3;

	return result;
}

sub :: inline (left : Mat4f, right : Mat4f) -> Mat4f #must
{
	result : Mat4f = ---;
	result.r0 = left.r0 - right.r0;
	result.r1 = left.r1 - right.r1;
	result.r2 = left.r2 - right.r2;
	result.r3 = left.r3 - right.r3;

	return result;
}

neg :: inline (mat : Mat4f) -> Mat4f #must
{
	result : Mat4f = ---;
	result.r0 = -mat.r0;
	result.r1 = -mat.r1;
	result.r2 = -mat.r2;
	result.r3 = -mat.r3;

	return result;
}

mul :: inline (left : Mat4f, right : f32) -> Mat4f #must
{
	result : Mat4f = ---;
	result.r0 = left.r0 * right;
	result.r1 = left.r1 * right;
	result.r2 = left.r2 * right;
	result.r3 = left.r3 * right;

	return result;
}

mul :: inline (left : Mat4f, right : Vec4f) -> Vec4f #must
{
	result : Vec4f = ---;
	result.n[0] = left.n[0][0] * right.n[0] + left.n[1][0] * right.n[1] + left.n[2][0] * right.n[2] + left.n[3][0] * right.n[3];
	result.n[1] = left.n[0][1] * right.n[0] + left.n[1][1] * right.n[1] + left.n[2][1] * right.n[2] + left.n[3][1] * right.n[3];
	result.n[2] = left.n[0][2] * right.n[0] + left.n[1][2] * right.n[1] + left.n[2][2] * right.n[2] + left.n[3][2] * right.n[3];
	result.n[3] = left.n[0][3] * right.n[0] + left.n[1][3] * right.n[1] + left.n[2][3] * right.n[2] + left.n[3][3] * right.n[3];

	return result;
}

mul :: inline (left : Mat4f, right : Mat4f) -> Mat4f #must
{
	result : Mat4f = ---;
	result.r0 = left * right.r0;
	result.r1 = left * right.r1;
	result.r2 = left * right.r2;
	result.r3 = left * right.r3;

	return result;
}

div :: inline (left : Mat4f, right : f32) -> Mat4f #must
{
	result : Mat4f = ---;
	result.r0 = left.r0 / right;
	result.r1 = left.r1 / right;
	result.r2 = left.r2 / right;
	result.r3 = left.r3 / right;

	return result;
}

equals :: inline (left : Mat4f, right : Mat4f) -> bool #must
{
	return equals (left.r0, right.r0) && equals (left.r1, right.r1) && equals (left.r2, right.r2) && equals (left.r3, right.r3);
}

approx_zero :: inline (mat : Mat4f, epsilon := F32_EPSILON) -> bool #must
{
	return approx_zero (mat.r0, epsilon) && approx_zero (mat.r1, epsilon) && approx_zero (mat.r2, epsilon) && approx_zero (mat.r3, epsilon);
}

approx_equals :: inline (left : Mat4f, right : Mat4f, epsilon := F32_EPSILON) -> bool #must
{
	return approx_equals (left.r0, right.r0, epsilon) && approx_equals (left.r1, right.r1, epsilon) && approx_equals (left.r2, right.r2, epsilon) && approx_equals (left.r3, right.r3, epsilon);
}

operator [] :: inline (mat : *Mat4f, row_index : s64) -> Vec4f #must
{
	return mat.rows[row_index];
}

operator + :: inline (left : Mat4f, right : Mat4f) -> Mat4f #must
{
	return add (left, right);
}

operator - :: inline (left : Mat4f, right : Mat4f) -> Mat4f #must
{
	return sub (left, right);
}

operator - :: inline (mat : Mat4f) -> Mat4f #must
{
	return neg (mat);
}

operator * :: inline (left : Mat4f, right : f32) -> Mat4f #must
	#symmetric
{
	return mul (left, right);
}

operator * :: inline (left : Mat4f, right : Vec4f) -> Vec4f #must
{
	return mul (left, right);
}

operator * :: inline (left : Mat4f, right : Mat4f) -> Mat4f #must
{
	return mul (left, right);
}

operator / :: inline (left : Mat4f, right : f32) -> Mat4f #must
{
	return div (left, right);
}

operator == :: inline (left : Mat4f, right : Mat4f) -> bool #must
{
	return equals (left, right);
}

operator != :: inline (left : Mat4f, right : Mat4f) -> bool #must
{
	return !equals (left, right);
}
