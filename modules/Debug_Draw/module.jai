#module_parameters (MAX_VERTICES := 10000);

#import "Core";
#import "Linalg";
#import "Math";
#import "Window";
#import "GL";
#import "Render_Core";
#import "Fmt";
#import "Font";

// @Todo (stefan): Have filled versions of all the draw functions, and choose
// either the filled version or the line version based on the context's variable

#load "lines.jai";
#load "triangles.jai";

Debug_Vertex :: struct
{
	position : Vec3f;
	tex_coords : Vec2f;
	color : RGBA;

	LAYOUT :: Vertex_Buffer.Elem.[
		Vertex_Buffer.VEC3F,
		Vertex_Buffer.VEC2F,
		Vertex_Buffer.RGBA
	];
}

Debug_Draw_Context :: struct
{
	window     : *Window;
	gl_context : *GL_Context;

	vertices : [MAX_VERTICES]Debug_Vertex;
	vertex_count : s64;
	draw_triangles := false;
	camera_transform : Mat4f;
	view_projection_matrix : Mat4f;
	use_depth_test := true;

	vertex_buffer : Vertex_Buffer;
	shader : Shader;
	texture : *Texture;
}

#add_context debug_draw : *Debug_Draw_Context;	// Currently active Debug_Draw context

debug_draw_check :: () #expand
{
	`debug_draw := context.debug_draw;
	assert (debug_draw != null, "No debug drawing context.");
}

debug_draw_create_context :: inline (window : *Window, gl_context : *GL_Context) -> *Debug_Draw_Context #must
{
	if !window || !gl_context
		return null;
	debug_draw := new (Debug_Draw_Context, HEAP_ALLOC);
	if !debug_draw
		return null;
	debug_draw.window = window;
	debug_draw.gl_context = gl_context;
	shader_ok, info_log := init_shader (*debug_draw.shader, GL_VERTEX_SHADER, GL_FRAGMENT_SHADER);
	if !shader_ok
	{
		log_error ("Could not load Debug Draw shader:\n%", info_log);
		debug_draw_destroy_context (debug_draw);

		return null;
	}
	init_vertex_buffer (*debug_draw.vertex_buffer, Debug_Vertex.LAYOUT);
	allocate_vertex_buffer_data (*debug_draw.vertex_buffer, MAX_VERTICES * size_of (Debug_Vertex), .DYNAMIC_DRAW);

	return debug_draw;
}

debug_draw_destroy_context :: inline (debug_draw : *Debug_Draw_Context)
{
	assert (context.debug_draw != debug_draw, "Cannot destroy Debug_Draw context because it is in use.");
	destroy_vertex_buffer (*debug_draw.vertex_buffer);
	destroy_shader (*debug_draw.shader);
	free (debug_draw, HEAP_ALLOC);
}

debug_draw_begin :: inline (debug_draw : *Debug_Draw_Context)
{
	assert (context.debug_draw != debug_draw, "Called debug_draw_begin before calling debug_draw_end on the same context.");
	assert (context.debug_draw == null, "Called debug_draw_begin but another context is in use.");
	assert (get_current_gl_context () == debug_draw.gl_context, "Current GL context does not match Debug_Draw GL context.");
	context.debug_draw = debug_draw;
}

debug_draw_end :: inline ()
{
	debug_draw_flush ();
	context.debug_draw = null;
}

debug_draw_flush :: inline ()
{
	debug_draw_check ();
	if debug_draw.vertex_count == 0
		return;
	prev_vertex_buffer := use_vertex_buffer (*debug_draw.vertex_buffer);
	defer use_vertex_buffer (*prev_vertex_buffer);
	prev_shader := use_shader (*debug_draw.shader);
	defer use_shader (*prev_shader);
	prev_texture := use_texture (debug_draw.texture);
	defer use_texture (*prev_texture);
	prev_framebuffer := use_framebuffer_for_drawing (null);
	defer use_framebuffer_for_drawing (*prev_framebuffer);

	viewport_w, viewport_h := get_viewport_size (debug_draw.window);
	glViewport (0, 0, xx viewport_w, xx viewport_h);
	set_shader_parameter (*debug_draw.shader, "u_View_Projection_Matrix", debug_draw.view_projection_matrix);
	set_shader_parameter (*debug_draw.shader, "u_Rendering_Text", debug_draw.texture != null);

	glDisable (GL_SCISSOR_TEST);
	if debug_draw.use_depth_test
		glEnable (GL_DEPTH_TEST);
	else
		glDisable (GL_DEPTH_TEST);
	glEnable (GL_BLEND);
	glBlendFunc (GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

	set_vertex_buffer_data (*debug_draw.vertex_buffer, debug_draw.vertices.data, debug_draw.vertex_count * size_of (Debug_Vertex));
	if debug_draw.draw_triangles
		glDrawArrays (GL_TRIANGLES, 0, xx debug_draw.vertex_count);
	else
		glDrawArrays (GL_LINES, 0, xx debug_draw.vertex_count);
	debug_draw.vertex_count = 0;
}

debug_draw_reserve :: inline (count : s64) -> *Debug_Vertex #must
{
	assert (count < MAX_VERTICES, "Reserving too many vertices (requested %, maximum is %).", count, MAX_VERTICES);
	debug_draw_check ();
	if debug_draw.vertex_count + count > MAX_VERTICES
		debug_draw_flush ();
	result := *debug_draw.vertices[debug_draw.vertex_count];
	debug_draw.vertex_count += count;

	return result;
}

debug_draw_get_mode :: inline () -> bool #must
{
	debug_draw_check ();

	return debug_draw.draw_triangles;
}

debug_draw_set_mode :: inline (draw_triangles : bool) -> previous : bool
{
	debug_draw_check ();
	if draw_triangles != debug_draw.draw_triangles
		debug_draw_flush ();
	previous := debug_draw.draw_triangles;
	debug_draw.draw_triangles = draw_triangles;

	return previous;
}

debug_draw_set_depth_test :: inline (use_depth_test : bool) -> previous : bool
{
	debug_draw_check ();
	if use_depth_test != debug_draw.use_depth_test
		debug_draw_flush ();
	previous := debug_draw.use_depth_test;
	debug_draw.use_depth_test = use_depth_test;

	return previous;
}

#scope_module

// @Note (stefan): Only used for text rendering, so this is module scoped.

debug_draw_get_texture :: inline () -> *Texture #must
{
	debug_draw_check ();

	return debug_draw.texture;
}

debug_draw_set_texture :: inline (texture : *Texture) -> previous : *Texture
{
	debug_draw_check ();
	if texture != debug_draw.texture
		debug_draw_flush ();
	previous := debug_draw.texture;
	debug_draw.texture = texture;

	return previous;
}

#scope_file

GL_VERTEX_SHADER :: #string GLSL
#version 330 core

layout (location = 0) in vec3 a_Position;
layout (location = 1) in vec2 a_Tex_Coords;
layout (location = 2) in vec4 a_Color;

out vec2 Tex_Coords;
out vec4 Color;

uniform mat4 u_View_Projection_Matrix;

void main ()
{
	gl_Position = u_View_Projection_Matrix * vec4 (a_Position, 1);
	Tex_Coords = a_Tex_Coords;
	Color = a_Color;
}
GLSL

GL_FRAGMENT_SHADER :: #string GLSL
#version 330 core

in vec2 Tex_Coords;
in vec4 Color;

out vec4 Frag_Color;

uniform sampler2D u_Glyph_Texture;
uniform bool u_Rendering_Text;

void main ()
{
	float alpha = 1.0;
	if (u_Rendering_Text)
		alpha = texture (u_Glyph_Texture, Tex_Coords).r;
	Frag_Color = vec4 (Color.r, Color.g, Color.b, Color.a * alpha);
}
GLSL
