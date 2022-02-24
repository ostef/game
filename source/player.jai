Player :: struct
{
	MAX_VELOCITY :: 1000.0;
	MOVEMENT_SPEED :: 4.0;
	MOVEMENT_RESPONSIVENESS :: 0.1;
	ROTATION_RESPONSIVENESS :: 0.1;
	GRAVITY_MULTIPLIER :: 3.0;
	GRAVITY :: 9.81 * GRAVITY_MULTIPLIER;	// A force, in u/s^2 or N
	JUMP_VELOCITY :: 4.0 * #run sqrt (GRAVITY_MULTIPLIER);	// In u/s
	JUMP_MAX_MULTIPLIER :: 3.0;
	WEB_MAX_LENGTH :: 200.0;
	WEB_CAST_COUNT :: 50;
	WEB_CAST_START_ANGLE_HORIZONTAL :: 10.0;
	WEB_CAST_ANGLE_HORIZONTAL :: 60.0;
	WEB_CAST_START_ANGLE_VERTICAL   :: 45.0;
	WEB_CAST_ANGLE_VERTICAL :: 30.0;
	SWING_JUMP_VELOCITY :: 4.0 * #run sqrt (GRAVITY_MULTIPLIER);
	SWING_STEERING :: 0.5;
	HEIGHT :: 1.8;
	MASS :: 70;	// In kg

	position : Vec3f;
	velocity : Vec3f;	// In u/s
	rotation := QUATF_IDENTITY;

	on_ground : bool;

	current_movement_speed : f32;
	target_movement_speed : f32;
	movement_direction : Vec3f;
	target_rotation := QUATF_IDENTITY;

	jump_multiplier : f32;

	web_attached : bool;
	web_length := 10.0;
	web_attach_point : Vec3f;

	transform := MAT4F_IDENTITY;
}

update_player :: (using player : *Player, camera : *Camera, delta_time : f32)
{
	left_mouse := is_mouse_button_pressed (.LEFT);
	right_mouse := is_mouse_button_pressed (.RIGHT);
	if left_mouse || right_mouse
	{
		if !web_attached
		{
			found, point, distance := find_web_attach_point (player, camera, left_mouse);
			if found
			{
				web_attached = true;
				web_attach_point = point;
				web_length = distance;
			}
		}
		else
			web_attached = false;
	}

	movement_input := vec2f (
		cast (f32) is_key_down (.D) - cast (f32) is_key_down (.A),
		cast (f32) is_key_down (.W) - cast (f32) is_key_down (.S)
	);
	movement_input = normalized (movement_input);
	if on_ground
	{
		target_movement_speed = length (movement_input) * MOVEMENT_SPEED;
		if is_key_down (.LEFT_SHIFT)
			target_movement_speed *= 3;
		current_movement_speed = lerp (current_movement_speed, target_movement_speed, MOVEMENT_RESPONSIVENESS);
	}

	if on_ground && movement_input != VEC2F_ZERO
	{
		movement_rotation := quatf_look_at (vec3f (movement_input.x, 0, movement_input.y));
		target_rotation = movement_rotation * quatf_axis_angle (UP_VECTOR, camera.euler_angles.yaw);
	}
	else if !on_ground && web_attached
		target_rotation = quatf_look_at (vec3f (velocity.x, 0, velocity.z));
	rotation = nlerp (rotation, target_rotation, ROTATION_RESPONSIVENESS);
	movement_direction = forward_vector (target_rotation);
	// Apply gravity
	// Gravity is a force, so it is expressed in N, or u/s^2
	// We need to multiply by delta time to convert to u/s
	velocity.y -= GRAVITY * delta_time;
	// Jump
	if on_ground
	{
		if is_key_released (.SPACE)
		{
			velocity.y = JUMP_VELOCITY * jump_multiplier;
			current_movement_speed *= jump_multiplier;
			jump_multiplier = 0;
		}
		velocity = UP_VECTOR * velocity.y
			+ movement_direction * current_movement_speed;
	}
	// Web swinging!
	if web_attached
	{
		next_position := position + velocity * delta_time;
		web_to_player := (next_position + UP_VECTOR * HEIGHT) - web_attach_point;
		normal, len := normalized (web_to_player);
		if len > web_length
		{
			next_position -= normal * (len - web_length);
			velocity = (next_position - position) / delta_time;
		}
		if is_key_released (.SPACE)
		{
			velocity += normalized (velocity) * SWING_JUMP_VELOCITY * jump_multiplier;
			web_attached = false;
		}
	}
	if (on_ground || web_attached) && is_key_down (.SPACE)
		jump_multiplier = clamp (jump_multiplier + 5 * delta_time, 1, JUMP_MAX_MULTIPLIER);
	else
		jump_multiplier = 0;
	velocity = clamp (velocity, -VEC3F_ONE * MAX_VELOCITY, VEC3F_ONE * MAX_VELOCITY);
	// Apply velocity
	position += velocity * delta_time;
	// Check for ground
	if position.y <= 0
	{
		position.y = 0;
		on_ground = true;
		velocity.y = 0;
	}
	else
		on_ground = false;
	// Update transform
	transform = mat4f_transform (position, rotation);
}

find_web_attach_point :: (using player : *Player, camera : *Camera, at_left : bool, $debug_draw := false) -> found : bool, point : Vec3f, distance : f32
{
	up := up_vector (transform);
	right := right_vector (camera.transform);
	forward := cross (right, up);
	if at_left
		right = -right;

	for vert :
		semi_circle (
			to_rads (WEB_CAST_START_ANGLE_VERTICAL + WEB_CAST_ANGLE_VERTICAL),
			to_rads (-WEB_CAST_ANGLE_VERTICAL),
			cast (s64) sqrt (WEB_CAST_COUNT)
		)
	{
		for hori :
			semi_circle (
				to_rads (WEB_CAST_START_ANGLE_HORIZONTAL),
				to_rads (WEB_CAST_ANGLE_HORIZONTAL),
				cast (s64) sqrt (WEB_CAST_COUNT)
			)
		{
			cast_origin := position + UP_VECTOR * HEIGHT;
			cast_direction := normalized (
				right * hori.y
				+ forward* vert.x
				+ up * vert.y
			);
			intersects, distance := line_cast (
				cast_origin,
				cast_direction,
				WEB_MAX_LENGTH
			);
#if debug_draw
{
			debug_draw_line (cast_origin, cast_origin + cast_direction * WEB_MAX_LENGTH, RGBA_WHITE);
			if intersects
				debug_draw_cross (cast_origin + cast_direction * distance, 0.5, RGBA_RED);
}
else
{
			if intersects && distance != 0
				return true, cast_origin + cast_direction * distance, distance;
}
		}
	}

	return false, VEC3F_ZERO, 0.0;
}

draw_player :: (using player : *Player)
{
	debug_draw_capsule (
		position,
		position + up_vector (transform) * HEIGHT,
		0.5,
		RGBA_GREEN
	);
	debug_draw_coordinates (transform);
	debug_draw_line (position, position + velocity, RGBA_GREEN);
	if web_attached
	{
		debug_draw_line (
			position + up_vector (transform) * HEIGHT,
			web_attach_point,
			RGBA_WHITE
		);
		debug_draw_sphere (
			web_attach_point,
			web_length,
			RGBA_RED,
			resolution = 100
		);
	}
	//find_web_attach_point (player, *camera, false, true);
	//find_web_attach_point (player, *camera, true, true);
}
