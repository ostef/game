Camera :: struct
{
	FLY_SPEED :: 1.0;
	ROTATION_SPEED :: 0.3;
	ROTATION_SMOOTHING :: 0.3;

	position : Vec3f;
	euler_angles : Euler_Angles;
	rotation := QUATF_IDENTITY;
	rotation_input : Vec2f;

	distance_to_target := 5.0;
	look_at_offset := Vec2f.{ 0, 2 };

	fov := 60.0;

	transform := MAT4F_IDENTITY;
	view_matrix := MAT4F_IDENTITY;
	projection_matrix := MAT4F_IDENTITY;
	view_projection_matrix := MAT4F_IDENTITY;
}

update_flying_camera :: (using camera : *Camera, delta_time : f32)
{
	mouse_delta : Vec2f;
	move_input  : Vec3f;
	move_speed  : f32;
	if is_window_focused (window)
	{
		move_speed = FLY_SPEED;
		mouse_delta = raw_mouse_delta;
		if is_key_down (.LEFT_SHIFT) then move_speed *= 10;
		move_speed *= delta_time;
		move_input.x = cast (f32) is_key_down (.D) - cast (f32) is_key_down (.A);
		move_input.y = cast (f32) is_key_down (.E) - cast (f32) is_key_down (.Q);
		move_input.z = cast (f32) is_key_down (.W) - cast (f32) is_key_down (.S);
	}
	move_input = normalized (move_input);
	position += right_vector (transform) * move_input.x * move_speed
		+ up_vector (transform) * move_input.y * move_speed
		+ forward_vector (transform) * move_input.z * move_speed;

	rotation_input = lerp (rotation_input, mouse_delta, ROTATION_SMOOTHING);
	delta := rotation_input * ROTATION_SPEED;
	euler_angles.yaw   += to_rads (delta.x);
	euler_angles.pitch += to_rads (delta.y);
	euler_angles.pitch = clamp (euler_angles.pitch, to_rads (-80.0), to_rads (80.0));
	rotation = quatf_euler_angles (euler_angles);

	transform = mat4f_transform (position, rotation);
	view_matrix = inverse (transform);
	viewport_w, viewport_h := get_viewport_size (window);
	aspect_ratio := viewport_w / cast (f32) viewport_h;
	projection_matrix = mat4f_perspective_projection (fov, aspect_ratio, 0.01, 1000.0);
	view_projection_matrix = view_matrix * projection_matrix;
}

update_game_camera :: (using camera : *Camera, target : Vec3f, delta_time : f32)
{
	mouse_delta : Vec2f;
	if is_window_focused (window)
		mouse_delta = raw_mouse_delta;

	rotation_input = lerp (rotation_input, mouse_delta, ROTATION_SMOOTHING);
	delta := rotation_input * ROTATION_SPEED;
	euler_angles.yaw   += to_rads (delta.x);
	euler_angles.pitch += to_rads (delta.y);
	euler_angles.pitch = clamp (euler_angles.pitch, to_rads (-80.0), to_rads (80.0));
	rotation = quatf_euler_angles (euler_angles);
	position = player.position
		+ right_vector (rotation) * look_at_offset.x
		+ UP_VECTOR * look_at_offset.y
		- forward_vector (rotation) * distance_to_target;

	transform = mat4f_transform (position, rotation);
	view_matrix = inverse (transform);
	viewport_w, viewport_h := get_viewport_size (window);
	aspect_ratio := viewport_w / cast (f32) viewport_h;
	projection_matrix = mat4f_perspective_projection (fov, aspect_ratio, 0.01, 1000.0);
	view_projection_matrix = view_matrix * projection_matrix;
}
