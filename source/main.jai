#import "Core";
#import "Math";
#import "Linalg";
#import "Fmt";
#import "Win32";
#import "File_System";
#import "GL";
#import "Window";
#import "Input";
#import "Config";
#import "Asset";
#import "Font";
#import "Render_Core";
#import "ImDraw";
#import "Debug_Draw";
#import "Anim_Core";

#load "player.jai";
#load "camera.jai";
#load "physics.jai";

window  : *Window;
font    : Font;
running : bool;
camera  : Camera;
player  : Player;
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
	}
}

draw_mesh :: inline (using mesh : *Mesh)
{
	prev_vertex_buffer := use_vertex_buffer (*vertex_buffer);
	defer use_vertex_buffer (*prev_vertex_buffer);
	prev_index_buffer := use_index_buffer (*index_buffer);
	defer use_index_buffer (*prev_index_buffer);
	glDrawElements (GL_TRIANGLES, cast (u32) indices.count, GL_UNSIGNED_INT, null);
}

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
	ok := load_font_from_file (*font, "data/JetBrainsMono-Regular.ttf");
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
	init_anim_core_asset_caches ();
	mannequin_mesh := load_asset (*skinned_mesh_assets, "data/blender/mannequin.mesh");
	if !mannequin_mesh
	{
		show_error_box ("Could not load mesh.");
		return;
	}
	defer release_asset (*skinned_mesh_assets, mannequin_mesh);
	mannequin_skeleton := load_asset (*skeleton_assets, "data/blender/mannequin.skel");
	if !mannequin_skeleton
	{
		show_error_box ("Could not load skeleton.");
		return;
	}
	defer release_asset (*skeleton_assets, mannequin_skeleton);
	shader : Shader;
	log : string;
	ok, log = init_shader (*shader, VERTEX_SHADER, FRAGMENT_SHADER);
	if !ok
	{
		log_error ("Could not load shader: %", log);
		show_error_box (window, "Could not load shader.");
		return;
	}
	defer destroy_shader (*shader);

	camera.position.z = -2;
	camera.position.y = 1;
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

		//update_player (*player, *camera, delta_time);
		update_flying_camera (*camera, delta_time);
		//update_game_camera (*camera, player.position, delta_time);
		debug_draw.camera_transform = camera.transform;
		debug_draw.view_projection_matrix = camera.view_projection_matrix;

		viewport_w, viewport_h := get_viewport_size (window);
		glViewport (0, 0, xx viewport_w, xx viewport_h);
		glClearColor (0.1, 0.1, 0.1, 1);
		glClear (GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

		debug_draw_begin (debug_draw);
			debug_draw_set_depth_test (true);
			//draw_aabb_colliders (RGBA_GREEN);
			//draw_player (*player);
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
		draw_mesh (mannequin_mesh);
		
		debug_draw_begin (debug_draw);
			debug_draw_set_depth_test (false);
			debug_draw_skeleton (mannequin_skeleton, rgba (255, 50, 100));
		debug_draw_end ();

		imdraw_begin (imdraw);
			imdraw_text (
				*font,
				22,
				vec2f (10, 10),
				fmt (TEMP_ALLOC, "% FPS", cast (int) (1 / delta_time)),
				RGBA_WHITE
			);
		imdraw_end ();
		
		swap_window_buffers (window);
		delta_time = cast (f32) (get_time () - frame_start);
	}
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
