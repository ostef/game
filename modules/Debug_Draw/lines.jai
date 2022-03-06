debug_draw_line :: inline (
	start : Vec3f,
	end : Vec3f,
	color : RGBA
)
{
	debug_draw_check ();
	debug_draw_set_mode (false);
	v := debug_draw_reserve (2);
	v.position = start;
	v.color = color;
	v += 1;
	v.position = end;
	v.color = color;
}

debug_draw_coordinates :: inline (
	position : Vec3f,
	right : Vec3f,
	up : Vec3f,
	forward : Vec3f,
	scale := 1.0
)
{
	debug_draw_line (position, position +   right * scale, RGBA_RED);
	debug_draw_line (position, position +      up * scale, RGBA_GREEN);
	debug_draw_line (position, position + forward * scale, RGBA_BLUE);
}

debug_draw_coordinates :: inline (
	matrix : Mat4f,
	scale := 1.0
)
{
	debug_draw_coordinates (translation_vector (matrix), right_vector (matrix), up_vector (matrix), forward_vector (matrix), scale);
}

debug_draw_cube :: inline (
	center : Vec3f,
	extents : Vec3f,
	right : Vec3f,
	up : Vec3f,
	forward : Vec3f,
	color : RGBA
)
{
	// Back
	debug_draw_line (
		center
			- right * extents.x * 0.5
			- up * extents.y * 0.5
			- forward * extents.z * 0.5,
		center
			+ right * extents.x * 0.5
			- up * extents.y * 0.5
			- forward * extents.z * 0.5,
		color
	);
	debug_draw_line (
		center
			- right * extents.x * 0.5
			+ up * extents.y * 0.5
			- forward * extents.z * 0.5,
		center
			+ right * extents.x * 0.5
			+ up * extents.y * 0.5
			- forward * extents.z * 0.5,
		color
	);
	debug_draw_line (
		center
			- right * extents.x * 0.5
			- up * extents.y * 0.5
			- forward * extents.z * 0.5,
		center
			- right * extents.x * 0.5
			+ up * extents.y * 0.5
			- forward * extents.z * 0.5,
		color
	);
	debug_draw_line (
		center
			+ right * extents.x * 0.5
			- up * extents.y * 0.5
			- forward * extents.z * 0.5,
		center
			+ right * extents.x * 0.5
			+ up * extents.y * 0.5
			- forward * extents.z * 0.5,
		color
	);
	// Front
	debug_draw_line (
		center
			- right * extents.x * 0.5
			- up * extents.y * 0.5
			+ forward * extents.z * 0.5,
		center
			+ right * extents.x * 0.5
			- up * extents.y * 0.5
			+ forward * extents.z * 0.5,
		color
	);
	debug_draw_line (
		center
			- right * extents.x * 0.5
			+ up * extents.y * 0.5
			+ forward * extents.z * 0.5,
		center
			+ right * extents.x * 0.5
			+ up * extents.y * 0.5
			+ forward * extents.z * 0.5,
		color
	);
	debug_draw_line (
		center
			- right * extents.x * 0.5
			- up * extents.y * 0.5
			+ forward * extents.z * 0.5,
		center
			- right * extents.x * 0.5
			+ up * extents.y * 0.5
			+ forward * extents.z * 0.5,
		color
	);
	debug_draw_line (
		center
			+ right * extents.x * 0.5
			- up * extents.y * 0.5
			+ forward * extents.z * 0.5,
		center
			+ right * extents.x * 0.5
			+ up * extents.y * 0.5
			+ forward * extents.z * 0.5,
		color
	);
	// Left
	debug_draw_line (
		center
			- right * extents.x * 0.5
			- up * extents.y * 0.5
			- forward * extents.z * 0.5,
		center
			- right * extents.x * 0.5
			- up * extents.y * 0.5
			+ forward * extents.z * 0.5,
		color
	);
	debug_draw_line (
		center
			- right * extents.x * 0.5
			+ up * extents.y * 0.5
			- forward * extents.z * 0.5,
		center
			- right * extents.x * 0.5
			+ up * extents.y * 0.5
			+ forward * extents.z * 0.5,
		color
	);
	// Right
	debug_draw_line (
		center
			+ right * extents.x * 0.5
			- up * extents.y * 0.5
			- forward * extents.z * 0.5,
		center
			+ right * extents.x * 0.5
			- up * extents.y * 0.5
			+ forward * extents.z * 0.5,
		color
	);
	debug_draw_line (
		center
			+ right * extents.x * 0.5
			+ up * extents.y * 0.5
			- forward * extents.z * 0.5,
		center
			+ right * extents.x * 0.5
			+ up * extents.y * 0.5
			+ forward * extents.z * 0.5,
		color
	);
}

debug_draw_aabb :: inline (
	center : Vec3f,
	extents : Vec3f,
	color : RGBA
)
{
	debug_draw_cube (center, extents, RIGHT_VECTOR, UP_VECTOR, FORWARD_VECTOR, color);
}

debug_draw_quad :: inline (
	center : Vec3f,
	extents : Vec2f,
	orientation : Quatf,
	color : RGBA
)
{
	debug_draw_quad (
		center,
		extents,
		rotate_vector (RIGHT_VECTOR, orientation),
		rotate_vector (UP_VECTOR, orientation),
		color
	);
}

debug_draw_quad :: inline (
	center : Vec3f,
	extents : Vec2f,
	right : Vec3f,
	up : Vec3f,
	color : RGBA
)
{
	bottom_left  := center - (right * extents.x * 0.5) - (up * extents.y * 0.5);
	bottom_right := center + (right * extents.x * 0.5) - (up * extents.y * 0.5);
	top_left     := center - (right * extents.x * 0.5) + (up * extents.y * 0.5);
	top_right    := center + (right * extents.x * 0.5) + (up * extents.y * 0.5);
	debug_draw_line (bottom_left, top_left, color);
	debug_draw_line (top_left, top_right, color);
	debug_draw_line (top_right, bottom_right, color);
	debug_draw_line (bottom_right, bottom_left, color);
}

debug_draw_grid :: inline (
	center : Vec3f,
	extents : Vec2f,
	cell_size : f32,
	right : Vec3f,
	up : Vec3f,
	color : RGBA
)
{
	bottom_left  := center - (right * extents.x * 0.5) - (up * extents.y * 0.5);
	bottom_right := center + (right * extents.x * 0.5) - (up * extents.y * 0.5);
	top_left     := center - (right * extents.x * 0.5) + (up * extents.y * 0.5);
	top_right    := center + (right * extents.x * 0.5) + (up * extents.y * 0.5);
	cells_x := cast (s64) (extents.x / cell_size);
	cells_y := cast (s64) (extents.y / cell_size);
	for x : 0..cells_x
		debug_draw_line (
			bottom_left + right * (x * cell_size),
			top_left + right * (x * cell_size),
			color
		);
	for y : 0..cells_y
		debug_draw_line (
			bottom_left + up * (y * cell_size),
			bottom_right + up * (y * cell_size),
			color
		);
}

debug_draw_sphere :: inline (
	center : Vec3f,
	radius : f32,
	color : RGBA,
	resolution := 25
)
{
	debug_draw_circle (center, radius, RIGHT_VECTOR, UP_VECTOR, color, resolution);
	debug_draw_circle (center, radius, RIGHT_VECTOR, FORWARD_VECTOR, color, resolution);
	debug_draw_circle (center, radius, FORWARD_VECTOR, UP_VECTOR, color, resolution);
}

debug_draw_cylinder :: inline (
	center : Vec3f,
	height : f32,
	radius : f32,
	right : Vec3f,
	up : Vec3f,
	color : RGBA,
	resolution := 25
)
{
	if radius <= 0
		return;
	if resolution <= 0
		resolution = max (cast (int) radius, 20);
	forward := cross (right, up);
	head := center + up * height * 0.5;
	tail := center - up * height * 0.5;
	theta := 2 * PI / cast (f32) resolution;
	tan_factor := tan (theta);
	rad_factor := cos (theta);
	p := vec2f (1, 0);
	for 0..resolution - 1
	{
		p0 := p;
		t := vec2f (-p.y, p.x);
		p += t * tan_factor;
		p *= rad_factor;
		p1 := p;

		debug_draw_line (
			head + (right * p0.x + forward * p0.y) * radius,
			head + (right * p1.x + forward * p1.y) * radius,
			color
		);
		debug_draw_line (
			head + (right * p0.x + forward * p0.y) * radius,
			tail + (right * p0.x + forward * p0.y) * radius,
			color
		);
		debug_draw_line (
			tail + (right * p0.x + forward * p0.y) * radius,
			tail + (right * p1.x + forward * p1.y) * radius,
			color
		);
	}
}

debug_draw_cylinder :: inline (
	start : Vec3f,
	end : Vec3f,
	radius : f32,
	color : RGBA,
	resolution := 25
)
{
	up, height := normalized (end - start);
	right := up_to_arbitrary_right_forward (up);
	debug_draw_cylinder (
		(start + end) * 0.5,
		height,
		radius,
		right,
		up,
		color,
		resolution
	);
}

debug_draw_capsule :: inline (
	start : Vec3f,
	end : Vec3f,
	radius : f32,
	color : RGBA,
	resolution := 25
)
{
	if resolution > 0 && resolution % 2 != 0
		resolution += 1;
	up, height := normalized (end - start);
	right, forward := up_to_arbitrary_right_forward (up);
	head   := start + up * radius;
	center := start + up * height * 0.5;
	tail   := end - up * radius;
	// Top half sphere
	debug_draw_semi_circle (head, radius, 0, -PI, right, up, color, resolution);
	debug_draw_semi_circle (head, radius, 0, -PI, forward, up, color, resolution);
	debug_draw_circle (head, radius, right, forward, color, resolution);
	// Bottom half sphere
	debug_draw_semi_circle (tail, radius, 0, -PI, right, -up, color, resolution);
	debug_draw_semi_circle (tail, radius, 0, -PI, forward, -up, color, resolution);
	debug_draw_circle (tail, radius, right, forward, color, resolution);
	// Body
	debug_draw_line (head + right * radius, tail + right * radius, color);
	debug_draw_line (head - right * radius, tail - right * radius, color);
	debug_draw_line (head + forward * radius, tail + forward * radius, color);
	debug_draw_line (head - forward * radius, tail - forward * radius, color);
}

debug_draw_semi_circle :: inline (
	center : Vec3f,
	radius : f32,
	start_angle : f32,
	angle : f32,
	orientation : Quatf,
	color : RGBA,
	resolution := -1
)
{
	if radius <= 0
		return;
	if resolution <= 0
		resolution = max (cast (int) radius, 20);
	debug_draw_semi_circle (
		center,
		radius,
		start_angle,
		angle,
		rotate_vector (RIGHT_VECTOR, orientation),
		rotate_vector (UP_VECTOR, orientation),
		color,
		resolution
	);
}

debug_draw_semi_circle :: inline (
	center : Vec3f,
	radius : f32,
	start_angle : f32,
	angle : f32,
	right : Vec3f,
	up : Vec3f,
	color : RGBA,
	resolution := -1
)
{
	debug_draw_check ();

	if radius <= 0
		return;
	if resolution <= 0
		resolution = max (cast (int) radius, 20);
	theta := angle / cast (f32) resolution;
	tan_factor := tan (theta);
	rad_factor := cos (theta);
	p := vec2f (cos (start_angle), sin (start_angle));
	v := debug_draw_reserve (resolution * 2);
	for 0..resolution - 1
	{
		v.position = center + (right * p.x + up * p.y) * radius;
		v.color = color;
		v += 1;
	
		t := vec2f (-p.y, p.x);
		p += t * tan_factor;
		p *= rad_factor;

		v.position = center + (right * p.x + up * p.y) * radius;
		v.color = color;
		v += 1;
	}
}

debug_draw_circle :: inline (
	center : Vec3f,
	radius : f32,
	orientation : Quatf,
	color : RGBA,
	resolution := -1
)
{
	debug_draw_circle (
		center,
		radius,
		rotate_vector (RIGHT_VECTOR, orientation),
		rotate_vector (UP_VECTOR, orientation),
		color,
		resolution
	);
}

debug_draw_circle :: inline (
	center : Vec3f,
	radius : f32,
	right : Vec3f,
	up : Vec3f,
	color : RGBA,
	resolution := 25
)
{
	debug_draw_semi_circle (center, radius, 0, 2 * PI, right, up, color, resolution);
}

debug_draw_cone :: inline (
	position : Vec3f,
	direction : Vec3f,
	height : f32,
	radius : f32,
	color : RGBA,
	resolution := 25
)
{
	if radius <= 0
		return;
	if resolution <= 0
		resolution = max (cast (int) radius, 20);
	right, up := forward_to_arbitrary_right_up (direction);
	center := position + direction * height;
	theta := 2 * PI / cast (f32) resolution;
	tan_factor := tan (theta);
	rad_factor := cos (theta);
	p := vec2f (1, 0);
	for 0..resolution - 1
	{
		debug_draw_line (
			position,
			center + (right * p.x + up * p.y) * radius,
			color
		);
		v := debug_draw_reserve (2);
		v.position = center + (right * p.x + up * p.y) * radius;
		v.color = color;
		v += 1;
	
		t := vec2f (-p.y, p.x);
		p += t * tan_factor;
		p *= rad_factor;

		v.position = center + (right * p.x + up * p.y) * radius;
		v.color = color;
		v += 1;
	}
}

debug_draw_frustum :: inline (
	position : Vec3f,
	direction : Vec3f,
	right : Vec3f,
	fov_in_degrees : f32,
	aspect : f32,
	near : f32,
	far : f32,
	color : RGBA
)
{
	up := normalized (cross (direction, right));
	near_t := tan (to_rads (fov_in_degrees) * 0.5) * near;
	near_b := -near_t;
	near_r := aspect * near_t;
	near_l := -near_r;
	near_extents := vec2f (abs (near_l - near_r), abs (near_b - near_t));
	debug_draw_quad (position + direction * near, near_extents, right, up, color);
	far_t := tan (to_rads (fov_in_degrees) * 0.5) * far;
	far_b := -far_t;
	far_r := aspect * far_t;
	far_l := -far_r;
	far_extents := vec2f (abs (far_l - far_r), abs (far_b - far_t));
	debug_draw_quad (position + direction * far, far_extents, right, up, color);

	debug_draw_line (
		position + direction * near - (right * near_extents.x - up * near_extents.y) * 0.5,
		position + direction *  far - (right * far_extents.x  - up * far_extents.y) * 0.5,
		color
	);
	debug_draw_line (
		position + direction * near + (right * near_extents.x - up * near_extents.y) * 0.5,
		position + direction *  far + (right * far_extents.x  - up * far_extents.y) * 0.5,
		color
	);
	debug_draw_line (
		position + direction * near - (right * near_extents.x + up * near_extents.y) * 0.5,
		position + direction *  far - (right * far_extents.x  + up * far_extents.y) * 0.5,
		color
	);
	debug_draw_line (
		position + direction * near + (right * near_extents.x + up * near_extents.y) * 0.5,
		position + direction *  far + (right * far_extents.x  + up * far_extents.y) * 0.5,
		color
	);
}

debug_draw_arrow :: inline (
	tail : Vec3f,
	head : Vec3f,
	size : f32,
	color : RGBA
)
{
	debug_draw_check ();
	debug_draw_line (tail, head, color);
	up := normalized (head - tail);
	right := up_to_arbitrary_right_forward (up);
	debug_draw_line (
		head,
		head + right * 0.05 - up * size,
		color
	);
	debug_draw_line (
		head,
		head - right * 0.05 - up * size,
		color
	);
}

debug_draw_cross :: inline (
	position : Vec3f,
	size : f32,
	color : RGBA
)
{
	debug_draw_line (
		position - RIGHT_VECTOR * 0.5 * size,
		position + RIGHT_VECTOR * 0.5 * size,
		color
	);
	debug_draw_line (
		position - UP_VECTOR * 0.5 * size,
		position + UP_VECTOR * 0.5 * size,
		color
	);
	debug_draw_line (
		position - FORWARD_VECTOR * 0.5 * size,
		position + FORWARD_VECTOR * 0.5 * size,
		color
	);
}

debug_draw_camera :: inline (
	position : Vec3f,
	direction : Vec3f,
	right : Vec3f,
	size : f32,
	color : RGBA
)
{
	cube_size := vec3f (0.3, 0.4, 0.6);
	cube_position := position - direction * (size - size * cube_size.z) * 0.5;
	cylinder_width := 0.2;
	cylinder_radius := 0.15;
	up := normalized (cross (direction, right));
	debug_draw_cylinder (
		cube_position
			- right * size * (cylinder_width * 0.5)
			+ up * size * 0.35
			- direction * size * 0.15,
		cube_position
			+ right * size * (cylinder_width * 0.5)
			+ up * size * 0.35
			- direction * size * 0.15,
		size * cylinder_radius,
		color
	);
	debug_draw_cylinder (
		cube_position
			- right * size * (cylinder_width * 0.5)
			+ up * size * 0.35
			+ direction * size * 0.15,
		cube_position
			+ right * size * (cylinder_width * 0.5)
			+ up * size * 0.35
			+ direction * size * 0.15,
		size * cylinder_radius,
		color
	);
	debug_draw_cube (cube_position, size * cube_size, right, up, direction, color);
	near := cube_size.z * 0.5;
	far  := 1 - near;
	debug_draw_frustum (cube_position, direction, right, 60, 9.0 / 16.0, size * near, size * far, color);
}
