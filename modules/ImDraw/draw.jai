#import "Font";

imdraw_triangle :: inline (
	p0 : Vec2f,
	p1 : Vec2f,
	p2 : Vec2f,
	color : RGBA,
	uv0 := Vec2f.{ 0, 0 },
	uv1 := Vec2f.{ 0.5, 1 },
	uv2 := Vec2f.{ 1, 0 }
)
{
	imdraw_check ();

	if p0 == p1 || p1 == p2 || p2 == p0
		return;

	v0 := imdraw_reserve (3);
	v0.position = p0;
	v0.tex_coords = uv0;
	v0.color = color;

	v1 := v0 + 1;
	v1.position = p1;
	v1.tex_coords = uv1;
	v1.color = color;

	v2 := v1 + 1;
	v2.position = p2;
	v2.tex_coords = uv2;
	v2.color = color;
}

imdraw_quad :: inline (
	p0 : Vec2f,
	p1 : Vec2f,
	p2 : Vec2f,
	p3 : Vec2f,
	color : RGBA,
	uv0 := Vec2f.{ 0, 0 },
	uv1 := Vec2f.{ 0, 1 },
	uv2 := Vec2f.{ 1, 1 },
	uv3 := Vec2f.{ 1, 0 }
)
{
	imdraw_check ();
	imdraw_triangle (
		p1,
		p0,
		p3,
		color,
		uv0 = uv1,
		uv1 = uv0,
		uv2 = uv3
	);
	imdraw_triangle (
		p1,
		p3,
		p2,
		color,
		uv0 = uv1,
		uv1 = uv3,
		uv2 = uv2
	);
}

imdraw_rect :: inline (
	rect : Rectf,
	color : RGBA,
	uv_rect := Rectf.{ 0, 0, 1, 1 }
)
{
	imdraw_check ();

	if rect.x1 >= rect.x2 || rect.y1 >= rect.y2
		return;
	imdraw_triangle (
		vec2f (rect.x1, rect.y2),
		vec2f (rect.x1, rect.y1),
		vec2f (rect.x2, rect.y1),
		color,
		uv0 = vec2f (uv_rect.x1, uv_rect.y2),
		uv1 = vec2f (uv_rect.x1, uv_rect.y1),
		uv2 = vec2f (uv_rect.x2, uv_rect.y1)
	);
	imdraw_triangle (
		vec2f (rect.x1, rect.y2),
		vec2f (rect.x2, rect.y1),
		vec2f (rect.x2, rect.y2),
		color,
		uv0 = vec2f (uv_rect.x1, uv_rect.y2),
		uv1 = vec2f (uv_rect.x2, uv_rect.y1),
		uv2 = vec2f (uv_rect.x2, uv_rect.y2)
	);
}

imdraw_rect :: inline (
	rect : Rectf,
	color : RGBA,
	corner_radius : f32,
	round_corners := Rectangle_Corners.ALL,
	uv_rect := Rectf.{ 0, 0, 1, 1 }
)
{
	imdraw_check ();

	if rect.x1 >= rect.x2 || rect.y1 >= rect.y2
		return;
	if corner_radius <= 0 || round_corners == .NONE
	{
		imdraw_rect (rect, color, uv_rect);

		return;
	}
	inner_rect    := truncate_all_sides (rect, corner_radius);
	uv_radius     := (corner_radius / rect_width (rect)) * rect_width (uv_rect);
	inner_uv_rect := truncate_all_sides (uv_rect, uv_radius);
	// Inner rect
	imdraw_triangle (
		vec2f (inner_rect.x1, inner_rect.y2),
		vec2f (inner_rect.x1, inner_rect.y1),
		vec2f (inner_rect.x2, inner_rect.y1),
		color,
		uv0 = vec2f (inner_uv_rect.x1, inner_uv_rect.y2),
		uv1 = vec2f (inner_uv_rect.x1, inner_uv_rect.y1),
		uv2 = vec2f (inner_uv_rect.x2, inner_uv_rect.y1)
	);
	imdraw_triangle (
		vec2f (inner_rect.x1, inner_rect.y2),
		vec2f (inner_rect.x2, inner_rect.y1),
		vec2f (inner_rect.x2, inner_rect.y2),
		color,
		uv0 = vec2f (inner_uv_rect.x1, inner_uv_rect.y2),
		uv1 = vec2f (inner_uv_rect.x2, inner_uv_rect.y1),
		uv2 = vec2f (inner_uv_rect.x2, inner_uv_rect.y2)
	);
	// Draw corners
	if flagged (round_corners, .TOP_LEFT)
		imdraw_semi_circle (
			rect_top_left (inner_rect),
			corner_radius,
			PI / 2,
			PI / 2,
			color,
			uv_center = rect_top_left (inner_uv_rect),
			uv_radius = uv_radius
		);
	else
		imdraw_rect (
			rectf (rect.x1, rect.y1, inner_rect.x1, inner_rect.y1),
			color,
			uv_rect = rectf (uv_rect.x1, uv_rect.y1, inner_uv_rect.x1, inner_uv_rect.y1)
		);
	if flagged (round_corners, .TOP_RIGHT)
		imdraw_semi_circle (
			rect_top_right (inner_rect),
			corner_radius,
			0,
			PI / 2,
			color,
			uv_center = rect_top_right (inner_uv_rect),
			uv_radius = uv_radius
		);
	else
		imdraw_rect (
			rectf (inner_rect.x2, rect.y1, rect.x2, inner_rect.y1),
			color,
			uv_rect = rectf (inner_uv_rect.x2, uv_rect.y1, uv_rect.x2, inner_uv_rect.y1)
		);
	if flagged (round_corners, .BOTTOM_LEFT)
		imdraw_semi_circle (
			rect_bottom_left (inner_rect),
			corner_radius,
			PI,
			PI / 2,
			color,
			uv_center = rect_bottom_left (inner_uv_rect),
			uv_radius = uv_radius
		);
	else
		imdraw_rect (
			rectf (rect.x1, inner_rect.y2, inner_rect.x1, rect.y2),
			color,
			uv_rect = rectf (uv_rect.x1, inner_uv_rect.y2, inner_uv_rect.x1, uv_rect.y2)
		);
	if flagged (round_corners, .BOTTOM_RIGHT)
		imdraw_semi_circle (
			rect_bottom_right (inner_rect),
			corner_radius,
			3 * PI / 2,
			PI / 2,
			color,
			uv_center = rect_bottom_right (inner_uv_rect),
			uv_radius = uv_radius
		);
	else
		imdraw_rect (
			rectf (inner_rect.x2, inner_rect.y2, rect.x2, rect.y2),
			color,
			uv_rect = rectf (inner_uv_rect.x2, inner_uv_rect.y2, uv_rect.x2, uv_rect.y2)
		);
	// Top
	imdraw_triangle (
		vec2f (inner_rect.x1, rect.y1),
		vec2f (inner_rect.x2, rect.y1),
		vec2f (inner_rect.x1, inner_rect.y1),
		color,
		uv0 = vec2f (inner_uv_rect.x1, uv_rect.y1),
		uv1 = vec2f (inner_uv_rect.x2, uv_rect.y1),
		uv2 = vec2f (inner_uv_rect.x1, inner_uv_rect.y1),
	);
	imdraw_triangle (
		vec2f (inner_rect.x1, inner_rect.y1),
		vec2f (inner_rect.x2, rect.y1),
		vec2f (inner_rect.x2, inner_rect.y1),
		color,
		uv0 = vec2f (inner_uv_rect.x1, inner_uv_rect.y1),
		uv1 = vec2f (inner_uv_rect.x2, uv_rect.y1),
		uv2 = vec2f (inner_uv_rect.x2, inner_uv_rect.y1),
	);
	// Right
	imdraw_triangle (
		vec2f (inner_rect.x2, inner_rect.y1),
		vec2f (rect.x2, inner_rect.y1),
		vec2f (rect.x2, inner_rect.y2),
		color,
		uv0 = vec2f (inner_uv_rect.x2, inner_uv_rect.y1),
		uv1 = vec2f (uv_rect.x2, inner_uv_rect.y1),
		uv2 = vec2f (uv_rect.x2, inner_uv_rect.y2),
	);
	imdraw_triangle (
		vec2f (inner_rect.x2, inner_rect.y1),
		vec2f (rect.x2, inner_rect.y2),
		vec2f (inner_rect.x2, inner_rect.y2),
		color,
		uv0 = vec2f (inner_uv_rect.x2, inner_uv_rect.y1),
		uv1 = vec2f (uv_rect.x2, inner_uv_rect.y2),
		uv2 = vec2f (inner_uv_rect.x2, inner_uv_rect.y2),
	);
	// Bottom
	imdraw_triangle (
		vec2f (inner_rect.x1, inner_rect.y2),
		vec2f (inner_rect.x2, inner_rect.y2),
		vec2f (inner_rect.x2, rect.y2),
		color,
		uv0 = vec2f (inner_uv_rect.x1, inner_uv_rect.y2),
		uv1 = vec2f (inner_uv_rect.x2, inner_uv_rect.y2),
		uv2 = vec2f (inner_uv_rect.x2, uv_rect.y2),
	);
	imdraw_triangle (
		vec2f (inner_rect.x1, inner_rect.y2),
		vec2f (inner_rect.x2, rect.y2),
		vec2f (inner_rect.x1, rect.y2),
		color,
		uv0 = vec2f (inner_uv_rect.x1, inner_uv_rect.y2),
		uv1 = vec2f (inner_uv_rect.x2, uv_rect.y2),
		uv2 = vec2f (inner_uv_rect.x1, uv_rect.y2),
	);
	// Left
	imdraw_triangle (
		vec2f (rect.x1, inner_rect.y1),
		vec2f (inner_rect.x1, inner_rect.y1),
		vec2f (inner_rect.x1, inner_rect.y2),
		color,
		uv0 = vec2f (uv_rect.x1, inner_uv_rect.y1),
		uv1 = vec2f (inner_uv_rect.x1, inner_uv_rect.y1),
		uv2 = vec2f (inner_uv_rect.x1, inner_uv_rect.y2),
	);
	imdraw_triangle (
		vec2f (rect.x1, inner_rect.y1),
		vec2f (inner_rect.x1, inner_rect.y2),
		vec2f (rect.x1, inner_rect.y2),
		color,
		uv0 = vec2f (uv_rect.x1, inner_uv_rect.y1),
		uv1 = vec2f (inner_uv_rect.x1, inner_uv_rect.y2),
		uv2 = vec2f (uv_rect.x1, inner_uv_rect.y2),
	);
}

imdraw_rect_outline :: inline (
	rect : Rectf,
	color : RGBA,
	thickness : f32,
	corner_radius := 0.0,
	round_corners := Rectangle_Corners.ALL,
	uv_rect := Rectf.{ 0, 0, 1, 1 }
)
{
	imdraw_check ();

	if rect.x1 >= rect.x2 || rect.y1 >= rect.y2
		return;

	inner_rect := truncate_all_sides (rect, thickness * 0.5);
	outer_rect := expand_all_sides (rect, thickness * 0.5);
	uv_thickness  := thickness / rect_width (rect) * rect_width (uv_rect);
	uv_radius     := (corner_radius / rect_width (rect)) * rect_width (uv_rect);
	inner_uv_rect := truncate_all_sides (uv_rect, uv_thickness * 0.5);
	outer_uv_rect := expand_all_sides (uv_rect, uv_thickness * 0.5);
	inset := corner_radius - thickness;
	uv_inset := uv_radius - uv_thickness;

	// Draw corners
	if flagged (round_corners, .TOP_LEFT)
		imdraw_semi_circle_outline (
			rect_top_left (inner_rect) + vec2f (inset, inset),
			corner_radius,
			PI / 2,
			PI / 2,
			color,
			thickness,
			uv_center = rect_top_left (inner_uv_rect),
			uv_radius = uv_radius
		);
	
	if flagged (round_corners, .TOP_RIGHT)
		imdraw_semi_circle_outline (
			rect_top_right (inner_rect) + vec2f (-inset, inset),
			corner_radius,
			0,
			PI / 2,
			color,
			thickness,
			uv_center = rect_top_right (inner_uv_rect),
			uv_radius = uv_radius
		);
	if flagged (round_corners, .BOTTOM_LEFT)
		imdraw_semi_circle_outline (
			rect_bottom_left (inner_rect) + vec2f (inset, -inset),
			corner_radius,
			PI,
			PI / 2,
			color,
			thickness,
			uv_center = rect_bottom_left (inner_uv_rect),
			uv_radius = uv_radius
		);
	if flagged (round_corners, .BOTTOM_RIGHT)
		imdraw_semi_circle_outline (
			rect_bottom_right (inner_rect) + vec2f (-inset, -inset),
			corner_radius,
			3 * PI / 2,
			PI / 2,
			color,
			thickness,
			uv_center = rect_bottom_right (inner_uv_rect),
			uv_radius = uv_radius
		);
	
	// Top
	imdraw_quad (
		vec2f (inner_rect.x1 + inset, inner_rect.y1),
		vec2f (inner_rect.x1 + inset, outer_rect.y1),
		vec2f (inner_rect.x2 - inset, outer_rect.y1),
		vec2f (inner_rect.x2 - inset, inner_rect.y1),
		color,
		vec2f (inner_uv_rect.x1 + uv_inset, inner_uv_rect.y1),
		vec2f (inner_uv_rect.x1 + uv_inset, outer_uv_rect.y1),
		vec2f (inner_uv_rect.x2 - uv_inset, outer_uv_rect.y1),
		vec2f (inner_uv_rect.x2 - uv_inset, inner_uv_rect.y1),
	);
	// Right
	imdraw_quad (
		vec2f (inner_rect.x2, inner_rect.y1 + inset),
		vec2f (outer_rect.x2, inner_rect.y1 + inset),
		vec2f (outer_rect.x2, inner_rect.y2 - inset),
		vec2f (inner_rect.x2, inner_rect.y2 - inset),
		color,
		vec2f (inner_uv_rect.x2, inner_uv_rect.y1 + uv_inset),
		vec2f (outer_uv_rect.x2, inner_uv_rect.y1 + uv_inset),
		vec2f (outer_uv_rect.x2, inner_uv_rect.y2 - uv_inset),
		vec2f (inner_uv_rect.x2, inner_uv_rect.y2 - uv_inset),
	);
	// Bottom
	imdraw_quad (
		vec2f (inner_rect.x1 + inset, outer_rect.y2),
		vec2f (inner_rect.x1 + inset, inner_rect.y2),
		vec2f (inner_rect.x2 - inset, inner_rect.y2),
		vec2f (inner_rect.x2 - inset, outer_rect.y2),
		color,
		vec2f (inner_uv_rect.x1 + uv_inset, outer_uv_rect.y2),
		vec2f (inner_uv_rect.x1 + uv_inset, inner_uv_rect.y2),
		vec2f (inner_uv_rect.x2 - uv_inset, inner_uv_rect.y2),
		vec2f (inner_uv_rect.x2 - uv_inset, outer_uv_rect.y2),
	);
	// Left
	imdraw_quad (
		vec2f (outer_rect.x1, inner_rect.y1 + inset),
		vec2f (inner_rect.x1, inner_rect.y1 + inset),
		vec2f (inner_rect.x1, inner_rect.y2 - inset),
		vec2f (outer_rect.x1, inner_rect.y2 - inset),
		color,
		vec2f (outer_uv_rect.x1, inner_uv_rect.y1 + uv_inset),
		vec2f (inner_uv_rect.x1, inner_uv_rect.y1 + uv_inset),
		vec2f (inner_uv_rect.x1, inner_uv_rect.y2 - uv_inset),
		vec2f (outer_uv_rect.x1, inner_uv_rect.y2 - uv_inset),
	);
}

imdraw_semi_circle :: inline (
	center : Vec2f,
	radius : f32,
	start_angle : f32,
	angle : f32,
	color : RGBA,
	resolution := 0,
	uv_center := Vec2f.{ 0.5, 0.5 },
	uv_radius := 0.5
)
{
	imdraw_check ();

	if radius <= 0
		return;
	if resolution <= 0
		resolution = max (cast (int) radius, 20);
	theta := -angle / cast (f32) resolution;
	tan_factor := tan (theta);
	rad_factor := cos (theta);
	p := vec2f (cos (-start_angle), sin (-start_angle));

	for 0..resolution - 1
	{
		p1 := p;
		t := vec2f (-p.y, p.x);
		p += t * tan_factor;
		p *= rad_factor;
		p2 := p;
		imdraw_triangle (
			center,
			center + p1 * radius,
			center + p2 * radius,
			color,
			uv0 = uv_center,
			uv1 = uv_center + p1 * uv_radius,
			uv2 = uv_center + p2 * uv_radius
		);
	}
}

imdraw_circle :: inline(
	center : Vec2f,
	radius : f32,
	color : RGBA,
	resolution := 0,
	uv_center := Vec2f.{ 0.5, 0.5 },
	uv_radius := 0.5
)
{
	imdraw_check ();
	imdraw_semi_circle (
		center,
		radius,
		0,
		2 * PI,
		color,
		resolution,
		uv_center,
		uv_radius
	);
}

imdraw_semi_circle_outline :: inline (
	center : Vec2f,
	radius : f32,
	start_angle : f32,
	angle : f32,
	color : RGBA,
	thickness : f32,
	resolution := 0,
	uv_center := Vec2f.{ 0.5, 0.5 },
	uv_radius := 0.5
)
{
	imdraw_check ();

	if radius <= 0
		return;
	
	if resolution <= 0
		resolution = max (cast (int) radius, 20);
	uv_thickness := thickness / radius * uv_radius;
	inner_radius := radius - thickness;
	inner_uv_radius := uv_radius - uv_thickness;
	theta := -angle / cast (f32) resolution;
	tan_factor := tan (theta);
	rad_factor := cos (theta);
	p := vec2f (cos (-start_angle), sin (-start_angle));
	
	for 0..resolution - 1
	{
		p1 := p;
		t := vec2f (-p.y, p.x);
		p += t * tan_factor;
		p *= rad_factor;
		p2 := p;
		imdraw_triangle (
			center + p1 * inner_radius,
			center + p1 * radius,
			center + p2 * radius,
			color,
			uv0 = uv_center + p1 * inner_uv_radius,
			uv1 = uv_center + p1 * uv_radius,
			uv2 = uv_center + p2 * uv_radius
		);
		imdraw_triangle (
			center + p1 * inner_radius,
			center + p2 * radius,
			center + p2 * inner_radius,
			color,
			uv0 = uv_center + p1 * inner_uv_radius,
			uv1 = uv_center + p2 * uv_radius,
			uv2 = uv_center + p2 * inner_uv_radius
		);
	}
}

imdraw_circle_outline :: inline (
	center : Vec2f,
	radius : f32,
	color : RGBA,
	thickness : f32,
	resolution := 0,
	uv_center := Vec2f.{ 0.5, 0.5 },
	uv_radius := 0.5
)
{
	imdraw_check ();
	imdraw_semi_circle_outline (
		center,
		radius,
		0,
		2 * PI,
		color,
		thickness,
		resolution,
		uv_center,
		uv_radius
	);
}

imdraw_line :: inline (
	start : Vec2f,
	end : Vec2f,
	color : RGBA,
	thickness : f32
)
{
	imdraw_check ();

	line_dir := normalized (end - start);
	theta    := atan2 (line_dir.x, -line_dir.y);
	cost     := cos (theta);
	sint     := sin (theta);
	offset   := vec2f (cost, sint) * thickness * 0.5;
	imdraw_triangle (start - offset, start + offset, end + offset, color);
	imdraw_triangle (start - offset, end + offset, end - offset, color);
}

imdraw_text :: inline (
	font : *Font,
	height : u32,
	position : Vec2f,
	text : string,
	color : RGBA
)
#no_abc
{
	imdraw_check ();

	prev_texture := imdraw_get_texture ();
	defer imdraw_set_texture (prev_texture);
	prev_shader := imdraw_set_shader (*glyph_shader);
	defer imdraw_set_shader (prev_shader);

	page := load_page (font, height);
	pen : Vec2f;
	pen.y += page.ascent;
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
				cast (f32) position.x + pen.x + glyph.bitmap_bearing_x,
				cast (f32) position.y + pen.y - glyph.bitmap_bearing_y,
				cast (f32) glyph.bitmap_width,
				cast (f32) glyph.bitmap_height
			);
			pen.x += glyph.advance;
			imdraw_set_texture (glyph.atlas_texture);
			imdraw_rect (glyph_rect, color, glyph.uv_rect);
		}
	}
}
