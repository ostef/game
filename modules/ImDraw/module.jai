#module_parameters (MAX_VERTICES := 10000);

#import "Core";
#import "Linalg";
#import "Math";
#import "Window";
#import "GL";
#import "Render_Core";

#load "draw.jai";

ImDraw_Vertex :: struct
{
	position   : Vec2f;
	tex_coords : Vec2f;
	color      : RGBA;

	LAYOUT :: Vertex_Buffer.Elem.[
		Vertex_Buffer.VEC2F,
		Vertex_Buffer.VEC2F,
		Vertex_Buffer.RGBA
	];
}

ImDraw_Context :: struct
{
	window     : *Window;
	gl_context : *GL_Context;

	vertices : [MAX_VERTICES]ImDraw_Vertex;
	vertex_count : s64;
	clip_rect : Recti;
	clipping_enabled : bool;
	viewport : Recti;

	texture        : *Texture;
	framebuffer    : *Framebuffer;
	shader         : *Shader;
	vertex_buffer  : Vertex_Buffer;
	default_shader : Shader;
}

#add_context imdraw : *ImDraw_Context;	// Currently active ImDraw context

Rectangle_Corners :: enum_flags
{
	NONE         :: 0x00;
	TOP_LEFT     :: 0x01;
	TOP_RIGHT    :: 0x02;
	BOTTOM_RIGHT :: 0x04;
	BOTTOM_LEFT  :: 0x08;
	ALL :: TOP_LEFT | TOP_RIGHT | BOTTOM_RIGHT | BOTTOM_LEFT;
}

imdraw_check :: () #expand
{
	`imdraw := context.imdraw;
	assert (imdraw != null, "No drawing context.");
}

imdraw_create_context :: inline (window : *Window, gl_context : *GL_Context) -> *ImDraw_Context #must
{
	if !window || !gl_context
		return null;
	imdraw := new (ImDraw_Context, HEAP_ALLOC);
	if !imdraw
		return null;
	imdraw.window = window;
	imdraw.gl_context = gl_context;
	shader_ok, info_log := init_shader (*imdraw.default_shader, GL_VERTEX_SHADER, GL_FRAGMENT_SHADER);
	if !shader_ok
	{
		log_error ("Could not load ImDraw default shader:\n%", info_log);
		imdraw_destroy_context (imdraw);

		return null;
	}
	init_vertex_buffer (*imdraw.vertex_buffer, ImDraw_Vertex.LAYOUT);
	allocate_vertex_buffer_data (*imdraw.vertex_buffer, MAX_VERTICES * size_of (ImDraw_Vertex), .DYNAMIC_DRAW);

	return imdraw;
}

imdraw_destroy_context :: inline (imdraw : *ImDraw_Context)
{
	assert (context.imdraw != imdraw, "Cannot destroy ImDraw context because it is in use; imdraw_end was not called.");
	destroy_vertex_buffer (*imdraw.vertex_buffer);
	destroy_shader (*imdraw.default_shader);
	free (imdraw, HEAP_ALLOC);
}

imdraw_begin :: inline (imdraw : *ImDraw_Context)
{
	assert (context.imdraw != imdraw, "Called imdraw_begin before calling imdraw_end on the same context.");
	assert (context.imdraw == null, "Called imdraw_begin but another context is in use.");
	assert (get_current_gl_context () == imdraw.gl_context, "Current GL context does not match ImDraw GL context.");
	context.imdraw = imdraw;
}

imdraw_end :: inline ()
{
	imdraw_flush ();
	context.imdraw = null;
}

imdraw_flush :: inline ()
{
	imdraw_check ();
	if imdraw.vertex_count == 0
		return;
	shader := ifx imdraw.shader then imdraw.shader else *imdraw.default_shader;
	prev_vertex_buffer := use_vertex_buffer (*imdraw.vertex_buffer);
	defer use_vertex_buffer (*prev_vertex_buffer);
	prev_shader := use_shader (shader);
	defer use_shader (*prev_shader);
	prev_texture := use_texture (imdraw.texture);
	defer use_texture (*prev_texture);
	prev_framebuffer := use_framebuffer_for_drawing (imdraw.framebuffer);
	defer use_framebuffer_for_drawing (*prev_framebuffer);

	viewport := imdraw.viewport;
	if !imdraw.framebuffer
	{
		viewport_w, viewport_h := get_viewport_size (imdraw.window);
		viewport.x1 = 0;
		viewport.y1 = 0;
		viewport.x2 = viewport_w;
		viewport.y2 = viewport_h;
	}
	view_projection := mat4f_orthographic_projection (
		cast (f32) viewport.x1,
		cast (f32) viewport.x2,
		cast (f32) viewport.y2,
		cast (f32) viewport.y1,
		0,
		1
	);
	glViewport (viewport.x1, viewport.y1, xx rect_width (viewport), xx rect_height (viewport));
	set_shader_parameter (shader, "u_View_Projection_Matrix", view_projection);
	set_shader_parameter (shader, "u_Use_Texture", imdraw.texture != null);

	if imdraw.clipping_enabled
	{
		clip_rect := imdraw.clip_rect;
		glEnable (GL_SCISSOR_TEST);
		new_y1 := rect_height (viewport) - clip_rect.y2;
		new_y2 := rect_height (viewport) - clip_rect.y1;
		clip_rect.y1 = new_y1;
		clip_rect.y2 = new_y2;
		glScissor (xx clip_rect.x1, xx clip_rect.y1, xx rect_width (clip_rect), xx rect_height (clip_rect));
	}
	defer glDisable (GL_SCISSOR_TEST);
	glDisable (GL_DEPTH_TEST);
	glEnable (GL_BLEND);
	glBlendFunc (GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

	set_vertex_buffer_data (*imdraw.vertex_buffer, imdraw.vertices.data, imdraw.vertex_count * size_of (ImDraw_Vertex));
	glDrawArrays (GL_TRIANGLES, 0, xx imdraw.vertex_count);
	imdraw.vertex_count = 0;
}

imdraw_reserve :: inline (count : s64) -> *ImDraw_Vertex #must
{
	assert (count < MAX_VERTICES, "Reserving too many vertices (requested %, maximum is %).", count, MAX_VERTICES);
	imdraw_check ();
	if imdraw.vertex_count + count > MAX_VERTICES
		imdraw_flush ();
	result := *imdraw.vertices[imdraw.vertex_count];
	imdraw.vertex_count += count;

	return result;
}

imdraw_get_clip_rect :: inline () -> Recti #must
{
	imdraw_check ();

	return imdraw.clip_rect;
}

imdraw_set_clip_rect :: inline (clip_rect : Recti) -> previous : Recti
{
	imdraw_check ();
	previous := imdraw.clip_rect;
	if previous != clip_rect || !imdraw.clipping_enabled then imdraw_flush ();
	imdraw.clipping_enabled = true;
	imdraw.clip_rect = clip_rect;
	using imdraw.clip_rect;
	if x1 > x2 then x1 = x2;
	if y1 > y2 then y1 = y2;

	return previous;
}

imdraw_push_clip_rect :: inline (clip_rect : Recti) -> previous : Recti
{
	imdraw_check ();
	if imdraw.clipping_enabled
		return imdraw_set_clip_rect (clip (clip_rect, imdraw.clip_rect));

	return imdraw_set_clip_rect (clip_rect);
}

imdraw_scope_clip_rect :: (clip_rect : Recti) #expand
{
	previous := imdraw_push_clip_rect (clip_rect);
	`defer imdraw_set_clip_rect (previous);
}

imdraw_get_clipping :: inline () -> bool #must
{
	imdraw_check ();

	return imdraw.clipping_enabled;
}

imdraw_set_clipping :: inline (enable : bool) -> previous : bool
{
	imdraw_check ();
	previous := imdraw.clipping_enabled;
	if previous != enable then imdraw_flush ();
	imdraw.clipping_enabled = enable;

	return previous;
}

imdraw_get_viewport :: inline () -> Recti #must
{
	imdraw_check ();

	return imdraw.viewport;
}

imdraw_set_viewport :: inline (viewport : Recti) -> Recti
{
	imdraw_check ();
	previous := imdraw.viewport;
	if previous != viewport then imdraw_flush ();
	imdraw.viewport = viewport;

	return previous;
}

imdraw_get_texture :: inline () -> *Texture #must
{
	imdraw_check ();

	return imdraw.texture;
}

imdraw_set_texture :: inline (texture : *Texture) -> previous : *Texture
{
	imdraw_check ();
	previous := imdraw.texture;
	if previous != texture then imdraw_flush ();
	imdraw.texture = texture;

	return previous;
}

imdraw_get_framebuffer :: inline () -> *Framebuffer #must
{
	imdraw_check ();

	return imdraw.framebuffer;
}

imdraw_set_framebuffer :: inline (framebuffer : *Framebuffer) -> *Framebuffer
{
	imdraw_check ();
	previous := imdraw.framebuffer;
	if previous != framebuffer then imdraw_flush ();
	imdraw.framebuffer = framebuffer;

	return previous;
}

imdraw_get_shader :: inline () -> *Shader #must
{
	imdraw_check ();

	return imdraw.shader;
}

imdraw_set_shader :: inline (shader : *Shader) -> *Shader
{
	imdraw_check ();
	previous := imdraw.shader;
	if previous != shader then imdraw_flush ();
	imdraw.shader = shader;

	return previous;
}

#scope_file

GL_VERTEX_SHADER :: #string GLSL
#version 330 core

layout (location = 0) in vec2 a_Position;
layout (location = 1) in vec2 a_Tex_Coords;
layout (location = 2) in vec4 a_Color;

out vec2 Tex_Coords;
out vec4 Color;

uniform mat4 u_View_Projection_Matrix;

void main ()
{
	gl_Position = u_View_Projection_Matrix * vec4 (a_Position, 0, 1);
	Tex_Coords = a_Tex_Coords;
	Color      = a_Color;
}
GLSL

GL_FRAGMENT_SHADER :: #string GLSL
#version 330 core

in vec2 Tex_Coords;
in vec4 Color;

out vec4 Frag_Color;

uniform sampler2D u_Texture;
uniform bool u_Use_Texture;

void main ()
{
	vec4 sampled = vec4 (1, 1, 1, 1);
	if (u_Use_Texture)
		sampled = texture (u_Texture, Tex_Coords);
	Frag_Color = sampled * Color;
}
GLSL
