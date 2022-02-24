#module_parameters (DEFAULT_FONT_ATLAS_WIDTH : u32 = 1024, DEFAULT_FONT_ATLAS_HEIGHT : u32 = 1024);

// @Note (stefan): We used to use ImDraw to draw the glyphs into a font atlas.
// The problem is, with the way we designed ImDraw contexts, we can't render glyphs
// in between debug_draw_begin and debug_draw_end calls because imdraw_begin hasn't
// been called. We can't have a Debug_Draw context and an ImDraw context active at
// the same time, because ImDraw is used for 2D, and draw calls should be made after
// every 3D draw calls. The thing is, Font draws to its own framebuffers, and it's ok
// in this case to mangle Debug_Draw and ImDraw flushes. But again, we can't have these
// two modules do their thing at the same time. All this is a problem because we 
// want to be able to draw debug text using Debug_Draw.
// The solution might be to make an ImDraw context specifically for the Font module,
// meaning we'd call imdraw_begin and imdraw_end for each glyph rendered. This is
// tedious, and we'd lose the benefit of using ImDraw anyway, since we won't be
// buffering vertices (although we already don't even do that in practice, since
// we almost always have a load_glyph_for_rendering followed by an imdraw_rect call,
// so we have a flush for both calls because we change the framebuffer).
// For this reason, I've decided instead to do the all the glyph rendering
// without ImDraw.
//
//											7 February 2022

#import "Core";
#import "Linalg";
#import "Math";
#import "Hash_Map";
#import "freetype255";
#import "GL";
#import "Render_Core";

Font :: struct
{
	filename : string;
	ft_face : FT_Face;
	pages : Hash_Map (u32, Font_Page);
}

Font_Glyph :: struct
{
	codepoint : u32;

	rendered : bool;
	width, height : u32;
	bearing_x, bearing_y : s32;
	advance : u32;
	bitmap_bearing_x, bitmap_bearing_y : s32;
	bitmap_width, bitmap_height : u32;

	uv_rect : Rectf;
	atlas_texture : *Texture;
}

Font_Page :: struct
{
	font    : *Font;
	height  : u32;
	atlases : [..]Font_Atlas;
	glyphs  : Hash_Map (u32, Font_Glyph);
	ascent, descent : s32;	// ascent is positive and goes upwards, descent is negative and goes downward. This might be confusing.
	space_advance : u32;
}

Font_Atlas :: struct
{
	texture     : Texture;
	framebuffer : Framebuffer;
	width, height : u32;
	pen_x, pen_y  : u32;
	row_end : u32;
}

#scope_file

Vertex :: struct
{
	position : Vec2f;
	tex_coords : Vec2f;
	color : RGBA;

	LAYOUT :: Vertex_Buffer.Elem.[
		Vertex_Buffer.VEC2F,
		Vertex_Buffer.VEC2F,
		Vertex_Buffer.RGBA,
	];
}

ft : *FT_Library;
rect_vertex_buffer : Vertex_Buffer;

#scope_export

glyph_shader : Shader;

init_fonts :: inline () -> bool
{
	ft_err := FT_Init_FreeType (*ft);
	if ft_err != FT_Err_Ok
	{
		log_error ("Could not initialize FreeType. Error was %.", ft_err);

		return false;
	}
	ok, info_log := init_shader (*glyph_shader, GL_GLYPH_VERTEX_SHADER, GL_GLYPH_FRAGMENT_SHADER);
	if !ok
	{
		log_error ("Could not initialize glyph shader:\n%", info_log);

		return false;
	}
	init_vertex_buffer (*rect_vertex_buffer, Vertex.LAYOUT);
	allocate_vertex_buffer_data (*rect_vertex_buffer, 6 * size_of (Vertex), .DYNAMIC_DRAW);

	return true;
}

load_font_from_file :: inline (font : *Font, filename : string) -> bool
{
	ft_face : FT_Face;
	ft_err := FT_New_Face (ft, clone_to_cstring (filename, TEMP_ALLOC), 0, *ft_face);
	if ft_err != FT_Err_Ok
	{
		log_error ("Could not load FT_Face from file '%'. Error was %.", filename, ft_err);

		return false;
	}
	font.filename = filename;
	font.ft_face = ft_face;
	init_map (*font.pages, 10, HEAP_ALLOC);

	return true;
}

reload_font_from_file :: inline (font : *Font, filename : string) -> bool
{
	cached := <<font;
	initialize_item (font);
	if !load_font_from_file (font, filename)
	{
		destroy_font (font);
		<<font = cached;

		return false;
	}
	destroy_font (*cached);

	return true;
}

destroy_font :: inline (using font : *Font)
{
	filename = "";
	FT_Done_Face (ft_face);
	ft_face = null;
	for * page, height : pages
	{
		for atlas, i : page.atlases
		{
			destroy_framebuffer (*atlas.framebuffer);
			destroy_texture (*atlas.texture);
		}
		reset_array (*page.atlases);
		reset_map (*page.glyphs);
	}
	reset_map (*pages);
}

load_page :: inline (using font : *Font, height : u32) -> *Font_Page
{
	page, was_present := insert_into_map (*pages, height);
	if was_present then return page;
	page.font   = font;
	page.height = height;
	init_array (*page.atlases, 3, HEAP_ALLOC);
	init_map (*page.glyphs, 512, HEAP_ALLOC);
	space_glyph := load_glyph (page, #char " ");
	page.ascent        = xx (ft_face.size.metrics.ascender >> 6);
	page.descent       = xx (ft_face.size.metrics.descender >> 6);
	page.space_advance = xx (space_glyph.advance);
	
	return page;
}

add_atlas_to_page :: inline (using page : *Font_Page, atlas_width := DEFAULT_FONT_ATLAS_WIDTH, atlas_height := DEFAULT_FONT_ATLAS_HEIGHT) -> *Font_Atlas
{
	result := push_into_array (*atlases);
	result.width  = atlas_width;
	result.height = atlas_height;
	init_texture (*result.texture, atlas_width, atlas_height, 4, null);
	init_framebuffer (*result.framebuffer, *result.texture);

	return result;
}

load_glyph :: inline (font : *Font, codepoint : u32, height : u32) -> *Font_Glyph
{
	page := load_page (font, height);
	
	return load_glyph (page, codepoint);
}

load_glyph_for_rendering :: inline (font : *Font, codepoint : u32, height : u32) -> *Font_Glyph
{
	page := load_page (font, height);
	
	return load_glyph_for_rendering (page, codepoint);
}

load_glyph :: (using page : *Font_Page, codepoint : u32) -> *Font_Glyph
{
	glyph, was_present := insert_into_map (*glyphs, codepoint);
	if was_present
		return glyph;

	FT_Set_Pixel_Sizes (font.ft_face, 0, height);
	ft_error := FT_Load_Char (font.ft_face, codepoint, FT_LOAD_DEFAULT);
	assert (ft_error == FT_Err_Ok, "Could not load glyph %.", codepoint);
	slot := font.ft_face.glyph;
	
	glyph.codepoint = codepoint;
	glyph.width     = xx (slot.metrics.width  >> 6);
	glyph.height    = xx (slot.metrics.height >> 6);
	glyph.bearing_x = xx (slot.metrics.horiBearingX >> 6);
	glyph.bearing_y = xx (slot.metrics.horiBearingY >> 6);
	glyph.advance   = xx (slot.metrics.horiAdvance >> 6);
	
	glyph.bitmap_width     = xx slot.bitmap.width;
	glyph.bitmap_height    = xx slot.bitmap.rows;
	glyph.bitmap_bearing_x = xx slot.bitmap_left;
	glyph.bitmap_bearing_y = xx slot.bitmap_top;

	return glyph;
}

load_glyph_for_rendering :: (using page : *Font_Page, codepoint : u32) -> *Font_Glyph
{
	glyph, was_present := insert_into_map (*glyphs, codepoint);
	if was_present && glyph.rendered
		return glyph;

	FT_Set_Pixel_Sizes (font.ft_face, 0, height);
	ft_error := FT_Load_Char (font.ft_face, codepoint, FT_LOAD_RENDER);
	assert (ft_error == FT_Err_Ok, "Could not load glyph %.", codepoint);
	slot := font.ft_face.glyph;
	
	glyph.codepoint = codepoint;
	glyph.width     = xx (slot.metrics.width  >> 6);
	glyph.height    = xx (slot.metrics.height >> 6);
	glyph.bearing_x = xx (slot.metrics.horiBearingX >> 6);
	glyph.bearing_y = xx (slot.metrics.horiBearingY >> 6);
	glyph.advance   = xx (slot.metrics.horiAdvance >> 6);
	
	glyph.bitmap_width     = xx slot.bitmap.width;
	glyph.bitmap_height    = xx slot.bitmap.rows;
	glyph.bitmap_bearing_x = xx slot.bitmap_left;
	glyph.bitmap_bearing_y = xx slot.bitmap_top;

	atlas : *Font_Atlas;
	for * atlases
	{
		if it.width - it.pen_y > glyph.bitmap_width && it.height - it.pen_y > glyph.bitmap_height
		{
			atlas = it;
			
			break;
		}
	}
	
	if !atlas then atlas = add_atlas_to_page (page);

	if atlas.width - atlas.pen_x < glyph.bitmap_width || atlas.height - atlas.pen_y < glyph.bitmap_height
	{
		atlas.pen_x = 0;
		atlas.pen_y = atlas.row_end;
		atlas.row_end += glyph.bitmap_height;
	}

	glyph.uv_rect = rectf (
		atlas.pen_x / cast (f32) atlas.width,
		1 - atlas.pen_y / cast (f32) atlas.height,
		(atlas.pen_x + glyph.bitmap_width) / cast (f32) atlas.width,
		1 - (atlas.pen_y + glyph.bitmap_height) / cast (f32) atlas.height
	);
	glyph.atlas_texture = *atlas.texture;

	glyph_texture : Texture;
	init_texture (*glyph_texture, glyph.bitmap_width, glyph.bitmap_height, 1, slot.bitmap.buffer);
	defer destroy_texture (*glyph_texture);
	prev_texture := use_texture (*glyph_texture);
	defer use_texture (*prev_texture);
	prev_framebuffer := use_framebuffer_for_drawing (*atlas.framebuffer);
	defer use_framebuffer_for_drawing (*prev_framebuffer);
	prev_shader := use_shader (*glyph_shader);
	defer use_shader (*prev_shader);
	prev_vertex_buffer := use_vertex_buffer (*rect_vertex_buffer);
	defer use_vertex_buffer (*prev_vertex_buffer);
	glViewport (0, 0, xx atlas.width, xx atlas.height);
	glDisable (GL_SCISSOR_TEST);

	rect_vertices : [6]Vertex;
	rect_vertices[0].position = vec2f (xx atlas.pen_x, xx (atlas.pen_y + glyph.bitmap_height));
	rect_vertices[0].tex_coords = vec2f (0, 1);
	rect_vertices[0].color = RGBA_WHITE;
	rect_vertices[1].position = vec2f (xx atlas.pen_x, xx atlas.pen_y);
	rect_vertices[1].tex_coords = vec2f (0, 0);
	rect_vertices[1].color = RGBA_WHITE;
	rect_vertices[2].position = vec2f (xx (atlas.pen_x + glyph.bitmap_width), xx atlas.pen_y);
	rect_vertices[2].tex_coords = vec2f (1, 0);
	rect_vertices[2].color = RGBA_WHITE;

	rect_vertices[3] = rect_vertices[0];
	rect_vertices[4] = rect_vertices[2];
	rect_vertices[5].position = vec2f (xx (atlas.pen_x + glyph.bitmap_width), xx (atlas.pen_y + glyph.bitmap_height));
	rect_vertices[5].tex_coords = vec2f (1, 1);
	rect_vertices[5].color = RGBA_WHITE;

	view_projection := mat4f_orthographic_projection (0, cast (f32) atlas.width, cast (f32) atlas.height, 0, 0, 1);
	set_shader_parameter (*glyph_shader, "u_View_Projection_Matrix", view_projection);
	set_shader_parameter (*glyph_shader, "u_Use_Texture", true);
	set_vertex_buffer_data (*rect_vertex_buffer, rect_vertices.data, rect_vertices.count * size_of (Vertex));
	glDrawArrays (GL_TRIANGLES, 0, 6);

	atlas.pen_x += glyph.bitmap_width;
	atlas.row_end = max (atlas.row_end, atlas.pen_y + glyph.bitmap_height);
	glyph.rendered = true;

	return glyph;
}

calculate_text_extents :: inline (font : *Font, height : u32, text : string) -> Vec2f #must
{
	page := load_page (font, height);
	width : f32;
	pen := vec2f (0, cast (f32) page.ascent);
	for i : 0..text.count - 1
	{
		codepoint := cast (u32) text[i];
		if codepoint ==
		{
		case #char "\n";
			width = max (width, pen.x);
			pen.x = 0;
			pen.y += page.ascent - page.descent;
		case #char "\t";
			glyph := load_glyph (page, codepoint);
			pen.x = snap_up (pen.x + glyph.advance, page.space_advance * 4.0);
			width = max (width, pen.x);
		case;
			glyph := load_glyph (page, codepoint);
			pen.x += glyph.advance;
			width = max (width, pen.x);
		}
	}

	return vec2f (width, pen.y - page.descent);
}

#scope_file

// We have the same shader parameters as ImDraw requires so we can use
// this shader with ImDraw.

GL_GLYPH_VERTEX_SHADER :: #string GLSL
#version 330 core

layout (location = 0) in vec2 a_Position;
layout (location = 1) in vec2 a_Tex_Coords;
layout (location = 2) in vec4 a_Color;

uniform mat4 u_View_Projection_Matrix;

out vec4 Vertex_Color;
out vec2 Tex_Coords;

void main ()
{
	gl_Position = u_View_Projection_Matrix * vec4 (a_Position, 0, 1);
	Vertex_Color = a_Color;
	Tex_Coords = a_Tex_Coords;
}
GLSL

GL_GLYPH_FRAGMENT_SHADER :: #string GLSL
#version 330 core

in vec2 Tex_Coords;
in vec4 Vertex_Color;
out vec4 Frag_Color;

uniform sampler2D u_Texture;
uniform bool u_Use_Texture;

void main ()
{
	if (u_Use_Texture)
	{
		float alpha = texture (u_Texture, Tex_Coords).r;
		Frag_Color = vec4 (1, 1, 1, alpha) * Vertex_Color;
	}
	else
	{
		Frag_Color = Vertex_Color;
	}
}
GLSL
