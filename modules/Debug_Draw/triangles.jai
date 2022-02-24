debug_draw_triangle :: inline (
	p0 : Vec3f,
	p1 : Vec3f,
	p2 : Vec3f,
	color : RGBA
)
{
	debug_draw_check ();
	debug_draw_set_mode (true);
	v := debug_draw_reserve (3);
	v.position = p0;
	v.color = color;
	v += 1;
	v.position = p1;
	v.color = color;
	v += 1;
	v.position = p2;
	v.color = color;
}

Text_Alignment :: enum_flags
{
	NONE   :: 0x00;
	TOP    :: 0x01;
	MIDDLE :: 0x02;
	BOTTOM :: 0x04;
	LEFT   :: 0x08;
	CENTER :: 0x10;
	RIGHT  :: 0x20;

	TOP_LEFT   :: TOP | LEFT;
	TOP_CENTER :: TOP | CENTER;
	TOP_RIGHT  :: TOP | RIGHT;

	MIDDLE_LEFT   :: MIDDLE | LEFT;
	MIDDLE_CENTER :: MIDDLE | CENTER;
	MIDDLE_RIGHT  :: MIDDLE | RIGHT;
	
	BOTTOM_LEFT   :: BOTTOM | LEFT;
	BOTTOM_CENTER :: BOTTOM | CENTER;
	BOTTOM_RIGHT  :: BOTTOM | RIGHT;
}

debug_draw_text :: inline (
	font : *Font,
	height : u32,
	size : f32,
	position : Vec3f,
	text : string,
	right : Vec3f,
	up : Vec3f,
	color : RGBA,
	alignment := Text_Alignment.TOP_LEFT
)
{
	debug_draw_glyph :: inline (
		start : Vec3f,
		right : Vec3f,
		up : Vec3f,
		rect : Rectf,
		uv_rect : Rectf,
		color : RGBA)
	{
		v := debug_draw_reserve (6);
		v.position = start + right * rect.x1 - up * rect.y1;
		v.tex_coords = vec2f (uv_rect.x1, uv_rect.y1);
		v.color = color;
		v += 1;
		v.position = start + right * rect.x2 - up * rect.y2;
		v.tex_coords = vec2f (uv_rect.x2, uv_rect.y2);
		v.color = color;
		v += 1;
		v.position = start + right * rect.x1 - up * rect.y2;
		v.tex_coords = vec2f (uv_rect.x1, uv_rect.y2);
		v.color = color;
		v += 1;

		v.position = start + right * rect.x1 - up * rect.y1;
		v.tex_coords = vec2f (uv_rect.x1, uv_rect.y1);
		v.color = color;
		v += 1;
		v.position = start + right * rect.x2 - up * rect.y1;
		v.tex_coords = vec2f (uv_rect.x2, uv_rect.y1);
		v.color = color;
		v += 1;
		v.position = start + right * rect.x2 - up * rect.y2;
		v.tex_coords = vec2f (uv_rect.x2, uv_rect.y2);
		v.color = color;
		v += 1;
	}

	debug_draw_check ();
	debug_draw_set_mode (true);
	prev_texture := debug_draw_get_texture ();
	defer debug_draw_set_texture (prev_texture);

	page := load_page (font, height);
	scale := size / cast (f32) (page.ascent - page.descent);
	pen := vec2f (0, cast (f32) page.ascent);
	// By default, we are top-left aligned, so we don't
	// need to handle this alignment explicitly
	extents : Vec2f;
	if alignment != .TOP_LEFT
		extents = calculate_text_extents (font, height, text);
	if flagged (alignment, .MIDDLE)
		pen.y -= extents.y * 0.5;
	else if flagged (alignment, .BOTTOM)
		pen.y -= extents.y;
	if flagged (alignment, .CENTER)
		pen.x -= extents.x * 0.5;
	else if flagged (alignment, .RIGHT)
		pen.x -= extents.x;
	for i : 0..text.count - 1
	{
		codepoint := cast (u32) text[i];
		if codepoint ==
		{
		case #char "\n";
			pen.x = 0;
			pen.y += page.ascent - page.descent;
		case #char "\t";
			glyph := load_glyph_for_rendering (page, codepoint);
			pen.x = snap_up (pen.x + glyph.advance, page.space_advance * 4.0);
		case;
			glyph := load_glyph_for_rendering (page, codepoint);
			glyph_rect := xywhf (
				cast (f32) scale * (pen.x + glyph.bitmap_bearing_x),
				cast (f32) scale * (pen.y - glyph.bitmap_bearing_y),
				cast (f32) scale * glyph.bitmap_width,
				cast (f32) scale * glyph.bitmap_height
			);
			pen.x += glyph.advance;
			debug_draw_set_texture (glyph.atlas_texture);
			debug_draw_glyph (position, right, up, glyph_rect, truncate_all_sides (glyph.uv_rect, 0.0004), color);
		}
	}
}

debug_draw_distance :: inline (
	font : *Font,
	text_size : f32,
	start : Vec3f,
	end : Vec3f,
	color : RGBA,
	text_color := RGBA_WHITE,
	fmt_str := "{:.3}"
)
{
	debug_draw_check ();
	debug_draw_line (start, end, color);
	// Find arbitrary right and forward vectors
	up, height := normalized (end - start);
	right := up_to_arbitrary_right_forward (up);
	tip_size := min (0.1, height * 0.1);
	debug_draw_line (start - right * tip_size, start + right * tip_size, color);
	debug_draw_line (end - right * tip_size, end + right * tip_size, color);
	center := (start + end) * 0.5;
	// Compute forward, right and up vectors so the text faces the camera
	text_forward := -normalized (translation_vector (debug_draw.camera_transform) - center);
	text_right := right_vector (debug_draw.camera_transform);
	text_up := normalized (cross (text_forward, text_right));
	debug_draw_text (font, 22, text_size, center, fmt (TEMP_ALLOC, fmt_str, height), text_right, text_up, text_color, alignment = .MIDDLE_CENTER);
}
