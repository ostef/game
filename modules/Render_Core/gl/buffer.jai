Buffer_Usage :: enum
{
	STATIC_DRAW  :: 0;
	DYNAMIC_DRAW :: 1;
	STREAM_DRAW  :: 2;
	STATIC_READ  :: 3;
	DYNAMIC_READ :: 4;
	STREAM_READ  :: 5;
	STATIC_COPY  :: 6;
	DYNAMIC_COPY :: 7;
	STREAM_COPY  :: 8;
}

gl_get_usage :: inline (usage : Buffer_Usage) -> GLenum #must
{
	gl_usage : GLenum;
	if #complete usage ==
	{
	case .STATIC_DRAW;
		gl_usage = GL_STATIC_DRAW;
	case .DYNAMIC_DRAW;
		gl_usage = GL_DYNAMIC_DRAW;
	case .STREAM_DRAW;
		gl_usage = GL_STREAM_DRAW;
	case .STATIC_READ;
		gl_usage = GL_STATIC_READ;
	case .DYNAMIC_READ;
		gl_usage = GL_DYNAMIC_READ;
	case .STREAM_READ;
		gl_usage = GL_STREAM_READ;
	case .STATIC_COPY;
		gl_usage = GL_STATIC_COPY;
	case .DYNAMIC_COPY;
		gl_usage = GL_DYNAMIC_COPY;
	case .STREAM_COPY;
		gl_usage = GL_STREAM_COPY;
	}

	return gl_usage;
}

Vertex_Buffer :: struct
{
	Binding :: struct
	{
		vao, vbo : GLuint;
	}

	Elem :: struct
	{
		Kind :: enum
		{
			S8  :: 0;
			U8  :: 1;
			S16 :: 2;
			U16 :: 3;
			S32 :: 4;
			U32 :: 5;
			F32 :: 6;
			F64 :: 7;
		}

		kind  : Kind;
		count : s64;
		integer   : bool;
		normalize : bool;
	}

	Layout :: []Elem;

	VEC2F :: Elem.{ .F32, 2, false, false };
	VEC3F :: Elem.{ .F32, 3, false, false };
	VEC4F :: Elem.{ .F32, 4, false, false };
	VEC2I :: Elem.{ .S32, 2, false, false };
	VEC3I :: Elem.{ .S32, 3, false, false };
	VEC4I :: Elem.{ .S32, 4, false, false };
	RGBA  :: Elem.{ .U8,  4, false,  true };

	using binding : Binding;
}

get_elem_size :: inline (elem : Vertex_Buffer.Elem) -> u32 #must
{
	type_size : u32;
	if #complete elem.kind ==
	{
	case .S8; #through;
	case .U8;
		type_size = 1;
	case .S16; #through;
	case .U16;
		type_size = 2;
	case .S32; #through;
	case .U32; #through;
	case .F32;
		type_size = 4;
	case .F64;
		type_size = 8;
	}

	return type_size * cast (u32) elem.count;
}

get_layout_size :: inline (layout : Vertex_Buffer.Layout) -> u32 #must
{
	size : u32;
	for layout
		size += get_elem_size (it);

	return size;
}

gl_get_type :: inline (elem_kind : Vertex_Buffer.Elem.Kind) -> GLenum #must
{
	if #complete elem_kind ==
	{
	case .S8;
		return GL_BYTE;
	case .U8;
		return GL_UNSIGNED_BYTE;
	case .S16;
		return GL_SHORT;
	case .U16;
		return GL_UNSIGNED_SHORT;
	case .S32;
		return GL_INT;
	case .U32;
		return GL_UNSIGNED_INT;
	case .F32;
		return GL_FLOAT;
	case .F64;
		return GL_DOUBLE;
	}

	return 0;
}

init_vertex_buffer :: inline (buffer : *Vertex_Buffer, layout : Vertex_Buffer.Layout)
{
	glGenVertexArrays (1, *buffer.vao);
	glBindVertexArray (buffer.vao);
	defer glBindVertexArray (0);
	glGenBuffers (1, *buffer.vbo);
	glBindBuffer (GL_ARRAY_BUFFER, buffer.vbo);
	defer glBindBuffer (GL_ARRAY_BUFFER, 0);

	elem_offset : u32;
	vertex_size := get_layout_size (layout);
	for elem, i : layout
	{
		glEnableVertexAttribArray (xx i);
		if elem.kind == .F64
			glVertexAttribLPointer (xx i, xx elem.count, gl_get_type (elem.kind), vertex_size, cast (*void) elem_offset);
		else if elem.integer
			glVertexAttribIPointer (xx i, xx elem.count, gl_get_type (elem.kind), vertex_size, cast (*void) elem_offset);
		else
			glVertexAttribPointer (xx i, xx elem.count, gl_get_type (elem.kind), xx elem.normalize, vertex_size, cast (*void) elem_offset);
		elem_offset += get_elem_size (elem);
	}
}

destroy_vertex_buffer :: inline (buffer : *Vertex_Buffer)
{
	// @Note (stefan): In the documentation for glDeleteBuffers: "If a buffer object that is
	// currently bound is deleted, the binding reverts to 0 (the absence of any buffer object)."
	// Same for vertex arrays.
	glDeleteBuffers (1, *buffer.vbo);
	glDeleteVertexArrays (1, *buffer.vao);
	buffer.vbo = 0;
	buffer.vao = 0;
}

get_current_vertex_buffer_binding :: inline () -> Vertex_Buffer.Binding #must
{
	vao, vbo : s32;
	glGetIntegerv (GL_VERTEX_ARRAY_BINDING, *vao);
	glGetIntegerv (GL_ARRAY_BUFFER_BINDING, *vbo);
	result : Vertex_Buffer.Binding;
	result.vao = xx vao;
	result.vbo = xx vbo;

	return result;
}

use_vertex_buffer :: inline (binding : *Vertex_Buffer.Binding) -> previous : Vertex_Buffer.Binding
{
	previous := get_current_vertex_buffer_binding ();
	if !binding
	{
		glBindVertexArray (0);
		glBindBuffer (GL_ARRAY_BUFFER, 0);
	}
	else
	{
		glBindVertexArray (binding.vao);
		glBindBuffer (GL_ARRAY_BUFFER, binding.vbo);
	}

	return previous;
}

allocate_vertex_buffer_data :: inline (buffer : *Vertex_Buffer, size : s64, usage : Buffer_Usage, data := null)
{
	previous := use_vertex_buffer (buffer);
	defer use_vertex_buffer (*previous);
	glBufferData (GL_ARRAY_BUFFER, size, data, gl_get_usage (usage));
}

set_vertex_buffer_data :: inline (buffer : *Vertex_Buffer, data : *void, size : s64)
{
	previous := use_vertex_buffer (buffer);
	defer use_vertex_buffer (*previous);
	glBufferSubData (GL_ARRAY_BUFFER, 0, size, data);
}

Index_Buffer :: struct
{
	Binding :: struct
	{
		ibo : GLuint;
	}

	using binding : Binding;
}

init_index_buffer :: inline (buffer : *Index_Buffer)
{
	glGenBuffers (1, *buffer.ibo);
	glBindBuffer (GL_ELEMENT_ARRAY_BUFFER, buffer.ibo);
	glBindBuffer (GL_ELEMENT_ARRAY_BUFFER, 0);
}

destroy_index_buffer :: inline (buffer : *Index_Buffer)
{
	glDeleteBuffers (1, *buffer.ibo);
	buffer.ibo = 0;
}

get_current_index_buffer_binding :: inline () -> Index_Buffer.Binding #must
{
	ibo : s32;
	glGetIntegerv (GL_ELEMENT_ARRAY_BUFFER_BINDING, *ibo);
	result : Index_Buffer.Binding = ---;
	result.ibo = xx ibo;

	return result;
}

use_index_buffer :: inline (binding : *Index_Buffer.Binding) -> previous : Index_Buffer.Binding
{
	previous := get_current_index_buffer_binding ();
	if !binding
		glBindBuffer (GL_ELEMENT_ARRAY_BUFFER, 0);
	else
		glBindBuffer (GL_ELEMENT_ARRAY_BUFFER, binding.ibo);

	return previous;
}

allocate_index_buffer_data :: inline (buffer : *Index_Buffer, size : s64, usage : Buffer_Usage, data := null)
{
	previous := use_index_buffer (buffer);
	defer use_index_buffer (*previous);
	glBufferData (GL_ELEMENT_ARRAY_BUFFER, size, data, gl_get_usage (usage));
}

set_index_buffer_data :: inline (buffer : *Index_Buffer, data : *void, size : s64)
{
	previous := use_index_buffer (buffer);
	defer use_index_buffer (*previous);
	glBufferSubData (GL_ELEMENT_ARRAY_BUFFER, 0, size, data);
}
