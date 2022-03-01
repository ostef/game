#import "Core";
#import "Math";
#import "Linalg";
#import "Fmt";
#import "Win32";
#import "GL";
#import "Window";
#import "Input";
#import "Config";
#import "Render_Core";
#import "Font";
#import "ImDraw";
#import "Debug_Draw";
#import "File_System";

#load "player.jai";
#load "camera.jai";
#load "physics.jai";

window  : *Window;
font    : Font;
running : bool;
camera  : Camera;
player : Player;
raw_mouse_delta : Vec2f;

process_window_message :: inline (msg : Window_Message)
{
	if msg.kind ==
	{
	case .WINDOW_CLOSED;
		if msg.window == window then running = false;

	case .RAW_MOUSE_MOVED;
		raw_mouse_delta.x = cast (f32) msg.mouse_delta_x;
		raw_mouse_delta.y = cast (f32) msg.mouse_delta_y;

	case .MOUSE_MOVED;
		if msg.window == window && is_window_focused (msg.window)
		{
			width, height := get_viewport_size (msg.window);
			set_mouse_position (msg.window, width / 2, height / 2);
		}

	case .WINDOW_RECEIVED_FOCUS;
		if msg.window == window
			hide_cursor ();
	case .WINDOW_LOST_FOCUS;
		if msg.window == window
			show_cursor ();

	case .WINDOW_RESIZED;
		println ("Window resized: % %", msg.viewport_width, msg.viewport_height);
	}
}

Static_Vertex :: struct
{
	position : Vec3f;
	tex_coords : Vec2f;
	normal : Vec3f;

	LAYOUT :: Vertex_Buffer.Elem.[
		Vertex_Buffer.VEC3F,
		Vertex_Buffer.VEC2F,
		Vertex_Buffer.VEC3F
	];
}

Static_Mesh :: Mesh (Static_Vertex);

load_mesh :: (using mesh : *Static_Mesh, filename : string) -> bool
{
	file_contents, ok := read_entire_file (filename, HEAP_ALLOC);
	if !ok
		return log_error ("Could not read file '%'.", filename);
	file_data := file_contents.data;
	defer free (file_data, HEAP_ALLOC);

	if !starts_with (file_contents, "MeshTxt\n")
		return log_error ("Expected MeshTxt.");
	file_contents = advance (file_contents, "MeshTxt\n".count);
	if !starts_with (file_contents, "1.0.0\n")
		return log_error ("Expected file format version.");
	file_contents = advance (file_contents, "1.0.0\n".count);
	{
		val, read := string_to_u32 (file_contents);
		if !read
			return log_error ("Expected [yyyy].");
		file_contents = advance (file_contents, read + 1);
		val, read = string_to_u32 (file_contents);
		if !read
			return log_error ("Expected [mm].");
		file_contents = advance (file_contents, read + 1);
		val, read = string_to_u32 (file_contents);
		if !read
			return log_error ("Expected [dd].");
		file_contents = advance (file_contents, read + 1);
		val, read = string_to_u32 (file_contents);
		if !read
			return log_error ("Expected [HH].");
		file_contents = advance (file_contents, read + 1);
		val, read = string_to_u32 (file_contents);
		if !read
			return log_error ("Expected [MM].");
		file_contents = advance (file_contents, read + 1);
		val, read = string_to_u32 (file_contents);
		if !read
			return log_error ("Expected [SS].");
		file_contents = advance (file_contents, read + 1);
	}
	if !starts_with (file_contents, "vertex_count ")
		return log_error ("Expected vertex_count.");
	file_contents = advance (file_contents, "vertex_count ".count);
	val, read := string_to_u32 (file_contents);
	if !read
		return log_error ("Expected a u32.");
	file_contents = advance (file_contents, read + 1);
	vertices = alloc_array (Static_Vertex, val, HEAP_ALLOC);
	if !starts_with (file_contents, "triangle_count ")
		return log_error ("Expected triangle_count.");
	file_contents = advance (file_contents, "triangle_count ".count);
	val, read = string_to_u32 (file_contents);
	if !read
		return log_error ("Expected a u32.");
	file_contents = advance (file_contents, read + 1);
	indices = alloc_array (u32, val * 3, HEAP_ALLOC);
	for * vert : vertices
	{
		if !starts_with (file_contents, "v\n")
			return log_error ("Expected v\\n.");
		file_contents = advance (file_contents, "v\n".count);
		vert.position.x, read = string_to_f32 (file_contents);
		if !read
			return log_error ("Expected a f32.");
		file_contents = advance (file_contents, read + 1);
		vert.position.y, read = string_to_f32 (file_contents);
		if !read
			return log_error ("Expected a f32.");
		file_contents = advance (file_contents, read + 1);
		vert.position.z, read = string_to_f32 (file_contents);
		if !read
			return log_error ("Expected a f32.");
		file_contents = advance (file_contents, read + 1);
		vert.tex_coords.x, read = string_to_f32 (file_contents);
		if !read
			return log_error ("Expected a f32.");
		file_contents = advance (file_contents, read + 1);
		vert.tex_coords.y, read = string_to_f32 (file_contents);
		if !read
			return log_error ("Expected a f32.");
		file_contents = advance (file_contents, read + 1);
		vert.normal.x, read = string_to_f32 (file_contents);
		if !read
			return log_error ("Expected a f32.");
		file_contents = advance (file_contents, read + 1);
		vert.normal.y, read = string_to_f32 (file_contents);
		if !read
			return log_error ("Expected a f32.");
		file_contents = advance (file_contents, read + 1);
		vert.normal.z, read = string_to_f32 (file_contents);
		if !read
			return log_error ("Expected a f32.");
		file_contents = advance (file_contents, read + 1);
		joint : s16;
		joint, read = string_to_s16 (file_contents);
		if !read
			return log_error ("Expected a s16.");
		file_contents = advance (file_contents, read + 1);
		joint, read = string_to_s16 (file_contents);
		if !read
			return log_error ("Expected a s16.");
		file_contents = advance (file_contents, read + 1);
		joint, read = string_to_s16 (file_contents);
		if !read
			return log_error ("Expected a s16.");
		file_contents = advance (file_contents, read + 1);
		joint, read = string_to_s16 (file_contents);
		if !read
			return log_error ("Expected a s16.");
		file_contents = advance (file_contents, read + 1);

		weight : f32;
		weight, read = string_to_f32 (file_contents);
		if !read
			return log_error ("Expected a f32.");
		file_contents = advance (file_contents, read + 1);
		weight, read = string_to_f32 (file_contents);
		if !read
			return log_error ("Expected a f32.");
		file_contents = advance (file_contents, read + 1);
		weight, read = string_to_f32 (file_contents);
		if !read
			return log_error ("Expected a f32.");
		file_contents = advance (file_contents, read + 1);
	}
	triangles : [][3]u32;
	triangles.data = cast (*[3]u32) indices.data;
	triangles.count = indices.count / 3;
	for * tri : triangles
	{
		if !starts_with (file_contents, "t ")
			return log_error ("Expected t .");
		file_contents = advance (file_contents, "t ".count);
		(<<tri)[0], read = string_to_u32 (file_contents);
		if !read
			return log_error ("Expected a u32.");
		file_contents = advance (file_contents, read + 1);
		(<<tri)[1], read = string_to_u32 (file_contents);
		if !read
			return log_error ("Expected a u32.");
		file_contents = advance (file_contents, read + 1);
		(<<tri)[2], read = string_to_u32 (file_contents);
		if !read
			return log_error ("Expected a u32.");
		file_contents = advance (file_contents, read + 1);
	}

	return true;
}

draw_mesh :: (using mesh : *Mesh)
{
	prev_vertex_buffer := use_vertex_buffer (*vertex_buffer);
	defer use_vertex_buffer (*prev_vertex_buffer);
	prev_index_buffer := use_index_buffer (*index_buffer);
	defer use_index_buffer (*prev_index_buffer);
	glDrawElements (GL_TRIANGLES, cast (u32) indices.count, GL_UNSIGNED_INT, null);
}

VERTEX_SHADER :: #string GLSL
#version 330 core

layout (location = 0) in vec3 a_Position;
layout (location = 1) in vec2 a_Tex_Coords;
layout (location = 2) in vec3 a_Normal;

uniform mat4 u_View_Projection_Matrix;
uniform mat4 u_Model_Matrix;

out vec2 Tex_Coords;
out vec4 Color;

void main ()
{
	gl_Position = u_View_Projection_Matrix * u_Model_Matrix * vec4 (a_Position, 1);
	Tex_Coords = a_Tex_Coords;
	Color = vec4 (a_Normal, 1);
}
GLSL

FRAGMENT_SHADER :: #string GLSL
#version 330 core

in vec2 Tex_Coords;
in vec4 Color;

out vec4 Frag_Color;

void main ()
{
	Frag_Color = Color;
}
GLSL

main :: ()
{
	fill_default_context ();
	init_cvars ();
	defer println ("Program ended.");
	if !win32_init_window_context ()
		return;
	if !init_input ()
	{
		show_error_box (window, "Could not initialize input.");
		return;
	}
	if !load_gl ()
	{
		show_error_box ("Could not initialize GL.");
		return;
	}
	window = create_window (
		"Game",
		WINDOW_DEFAULT,
		WINDOW_DEFAULT,
		WINDOW_DEFAULT,
		WINDOW_DEFAULT,
		Window_Creation_Flags.VISIBLE
	);
	if !window
	{
		show_error_box ("Could not create game window.");
		return;
	}
	defer destroy_window (window);
	gl_context := create_gl_context (window, .MULTISAMPLED);
	if !gl_context
	{
		show_error_box (window, "Could not create GL context.");
		return;
	}
	defer destroy_gl_context (window, gl_context);
	if !init_fonts ()
		return;
	ok := load_font_from_file (*font, "JetBrainsMono-Regular.ttf");
	if !ok
	{
		show_error_box (window, "Could not load font 'JetBrainsMono-Regular.ttf'.");
		return;
	}
	imdraw := imdraw_create_context (window, gl_context);
	if !imdraw
	{
		show_error_box (window, "Could not create ImDraw context.");
		return;
	}
	defer imdraw_destroy_context (imdraw);
	debug_draw := debug_draw_create_context (window, gl_context);
	if !debug_draw
	{
		show_error_box (window, "Could not create Debug_Draw context.");
		return;
	}
	defer debug_draw_destroy_context (debug_draw);
	texture : Texture;
	if !load_texture_from_file (*texture, "uv_grid.png")
		log_error ("Could not load 'uv_grid.png'.");
	defer destroy_texture (*texture);
	mannequin_mesh : Static_Mesh;
	if !load_mesh (*mannequin_mesh, "data/blender/mannequin_text.mesh")
	{
		show_error_box (window, "Could not load mesh.");
		return;
	}
	init_mesh_buffers (*mannequin_mesh);
	defer destroy_mesh_buffers (*mannequin_mesh);
	shader : Shader;
	{
		ok, log := init_shader (*shader, VERTEX_SHADER, FRAGMENT_SHADER);
		if !ok
		{
			log_error ("Could not load shader: %", log);
			show_error_box (window, "Could not load shader.");
			return;
		}
	}

	i := 1;
	while i < 100
	{
		defer i += 2;
		add_aabb_collider (vec3f (40.0, 150, 40.0 * i), vec3f (20, 150, 20));
		add_aabb_collider (vec3f (40.0, 150, -40.0 * i), vec3f (20, 150, 20));
		add_aabb_collider (vec3f (-40.0, 150, 40.0 * i), vec3f (20, 150, 20));
		add_aabb_collider (vec3f (-40.0, 150, -40.0 * i), vec3f (20, 150, 20));
		add_aabb_collider (vec3f (40.0 * i, 150, 40.0), vec3f (20, 150, 20));
		add_aabb_collider (vec3f (40.0 * i, 150, -40.0), vec3f (20, 150, 20));
		add_aabb_collider (vec3f (-40.0 * i, 150, 40.0), vec3f (20, 150, 20));
		add_aabb_collider (vec3f (-40.0 * i, 150, -40.0), vec3f (20, 150, 20));
	}

	camera.position.z = -2;
	running = true;
	delta_time := 0.16;
	while running
	{
		frame_start := get_time ();
		reset_temporary_storage ();
		raw_mouse_delta = VEC2F_ZERO;
		msg : Window_Message = ---;
		pull_window_messages (window);
		while get_next_window_message (window, *msg)
			process_window_message (msg);
		if is_window_focused (window)
		{
			width, height := get_viewport_size (window);
			set_mouse_position (window, width / 2, height / 2);
			hide_cursor ();
		}
		update_input_state ();

		update_player (*player, *camera, delta_time);
		//update_flying_camera (*camera, delta_time);
		update_game_camera (*camera, player.position, delta_time);
		debug_draw.camera_transform = camera.transform;
		debug_draw.view_projection_matrix = camera.view_projection_matrix;

		viewport_w, viewport_h := get_viewport_size (window);
		glViewport (0, 0, xx viewport_w, xx viewport_h);
		glClearColor (0.1, 0.1, 0.1, 1);
		glClear (GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

		debug_draw_begin (debug_draw);
			draw_aabb_colliders (RGBA_GREEN);
			draw_player (*player);
			debug_draw_coordinates (MAT4F_IDENTITY);
			debug_draw_grid (vec3f (0, 0, 0), vec2f (400, 400), 1, RIGHT_VECTOR, FORWARD_VECTOR, rgba (255, 255, 255, 100));
		debug_draw_end ();

		glEnable (GL_CULL_FACE);
		glFrontFace (GL_CW);
		glDisable (GL_SCISSOR_TEST);
		glEnable (GL_DEPTH_TEST);
		use_shader (*shader);
		set_shader_parameter (*shader, "u_View_Projection_Matrix", camera.view_projection_matrix);
		set_shader_parameter (*shader, "u_Model_Matrix", player.transform);
		draw_mesh (*mannequin_mesh);
		
		imdraw_begin (imdraw);
			imdraw_text (
				*font,
				22,
				vec2f (10, 10),
				fmt (TEMP_ALLOC, "% FPS", cast (int) (1 / delta_time)),
				RGBA_WHITE
			);
			normalized_jump_multiplier := player.jump_multiplier / player.JUMP_MAX_MULTIPLIER;
			if player.jump_multiplier > 1
				imdraw_rect (
					rectf (10, lerp (100.0, 40.0, normalized_jump_multiplier), 20, 100),
					blend (RGBA_GREEN, RGBA_RED, normalized_jump_multiplier)
				);
		imdraw_end ();
		
		swap_window_buffers (window);
		delta_time = cast (f32) (get_time () - frame_start);
	}
}
