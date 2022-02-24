Shader :: struct
{
	Binding :: struct
	{
		spo : GLuint;
	}

	Parameter :: struct
	{
		Kind :: enum
		{
			UNKNOWN :: 0;
			BOOL;
			S32;
			VEC2I;
			VEC3I;
			VEC4I;
			U32;
			VEC2U;
			VEC3U;
			VEC4U;
			F32;
			VEC2F;
			VEC3F;
			VEC4F;
			MAT3F;
			MAT4F;
		}

		kind : Kind;
		name : string;
		count : s32;
		location : GLint;
	}

	using binding : Binding;
	parameters : []Parameter;
}

gl_get_shader_parameter_kind :: inline (type : GLenum) -> Shader.Parameter.Kind #must
{
	kind : Shader.Parameter.Kind;
	if type ==
	{
	case GL_BOOL;
		kind = .BOOL;
	case GL_INT;
		kind = .S32;
	case GL_INT_VEC2;
		kind = .VEC2I;
	case GL_INT_VEC3;
		kind = .VEC3I;
	case GL_INT_VEC4;
		kind = .VEC4I;
	case GL_UNSIGNED_INT;
		kind = .U32;
	case GL_UNSIGNED_INT_VEC2;
		kind = .VEC2U;
	case GL_UNSIGNED_INT_VEC3;
		kind = .VEC3U;
	case GL_UNSIGNED_INT_VEC4;
		kind = .VEC4U;
	case GL_FLOAT;
		kind = .F32;
	case GL_FLOAT_VEC2;
		kind = .VEC2F;
	case GL_FLOAT_VEC3;
		kind = .VEC3F;
	case GL_FLOAT_VEC4;
		kind = .VEC4F;
	case GL_FLOAT_MAT3;
		kind = .MAT3F;
	case GL_FLOAT_MAT4;
		kind = .MAT4F;
	}

	return kind;
}

init_shader :: inline (shader : *Shader, vertex_src : string, fragment_src : string, geometry_src := "") -> bool, info_log : string
{
	check_compile_errors :: (shader : GLuint) -> bool, info_log : string
	{
		success : s32;
		glGetShaderiv (shader, GL_COMPILE_STATUS, *success);
		if !success
		{
			info_len : s32;
			glGetShaderiv (shader, GL_INFO_LOG_LENGTH, *info_len);
			info_data := cast (*u8) alloc (info_len, TEMP_ALLOC);
			glGetShaderInfoLog (shader, xx info_len, xx *info_len, info_data);

			return false, make_string (info_data, info_len);
		}

		return true, "";
	}

	vso, gso, fso : GLuint;
	ok : bool;
	info_log : string;

	vso = glCreateShader (GL_VERTEX_SHADER);
	defer glDeleteShader (vso);
	glShaderSource (vso, 1, *clone_to_cstring (vertex_src, TEMP_ALLOC), null);
	glCompileShader (vso);
	ok, info_log = check_compile_errors (vso);
	if !ok
		return false, info_log;

	fso = glCreateShader (GL_FRAGMENT_SHADER);
	defer glDeleteShader (fso);
	glShaderSource (fso, 1, *clone_to_cstring (fragment_src, TEMP_ALLOC), null);
	glCompileShader (fso);
	ok, info_log = check_compile_errors (fso);
	if !ok
		return false, info_log;

	if geometry_src
	{
		gso = glCreateShader (GL_GEOMETRY_SHADER);
		defer glDeleteShader (gso);
		glShaderSource (gso, 1, *clone_to_cstring (geometry_src, TEMP_ALLOC), null);
		glCompileShader (gso);
		ok, info_log = check_compile_errors (gso);
		if !ok
			return false, info_log;
	}

	spo := glCreateProgram ();
	glAttachShader (spo, vso);
	glAttachShader (spo, fso);
	if geometry_src
		glAttachShader (spo, gso);
	glLinkProgram (spo);
	success : s32;
	glGetProgramiv (spo, GL_LINK_STATUS, *success);
	if !success
	{
		info_len : s32;
		glGetProgramiv (spo, GL_INFO_LOG_LENGTH, *info_len);
		info_data := cast (*u8) alloc (info_len, TEMP_ALLOC);
		glGetProgramInfoLog (spo, xx info_len, xx *info_len, info_data);
		glDeleteProgram (spo);
		
		return false, make_string (info_data, info_len);
	}

	shader.spo = spo;
	param_count : s32;
	glGetProgramiv (shader.spo, GL_ACTIVE_UNIFORMS, *param_count);
	shader.parameters.data = alloc (size_of (Shader.Parameter) * param_count, HEAP_ALLOC);
	shader.parameters.count = 0;
	name_data := cast (*u8) alloc (256, TEMP_ALLOC);
	for i : 0..param_count - 1
	{
		name_len  : u32;
		size : s32;
		type : GLenum;
		glGetActiveUniform (shader.spo, xx i, 256, *name_len, *size, *type, name_data);
		param : Shader.Parameter;
		param.kind = gl_get_shader_parameter_kind (type);
		if param.kind == .UNKNOWN
			continue;
		param.name = clone_string (make_string (name_data, name_len), HEAP_ALLOC);
		param.count = size;
		param.location = glGetUniformLocation (shader.spo, name_data);
		shader.parameters.data[shader.parameters.count] = param;
		shader.parameters.count += 1;
	}

	return true, "";
}

destroy_shader :: inline (shader : *Shader)
{
	for shader.parameters
		free (it.name, HEAP_ALLOC);
	free (shader.parameters, HEAP_ALLOC);
	glDeleteProgram (shader.spo);
	shader.spo = 0;
	shader.parameters = .[];
}

get_current_shader :: inline () -> Shader.Binding #must
{
	spo : s32;
	glGetIntegerv (GL_CURRENT_PROGRAM, *spo);
	result : Shader.Binding = ---;
	result.spo = xx spo;

	return result;
}

use_shader :: inline (binding : *Shader.Binding) -> previous : Shader.Binding
{
	previous := get_current_shader ();
	if !binding
		glUseProgram (0);
	else
		glUseProgram (binding.spo);

	return previous;
}

get_shader_parameter :: inline (shader : *Shader, name : string) -> Shader.Parameter, bool
{
	for shader.parameters
	{
		if it.name == name
			return it, true;
	}

	return .{}, false;
}

set_shader_parameter :: inline (shader : *Shader, name : string, val : bool) -> bool
{
	param, ok := get_shader_parameter (shader, name);
	if !ok || param.kind != .BOOL
		return false;
	glUniform1i (param.location, cast (s32) val);

	return true;
}

set_shader_parameter :: inline (shader : *Shader, name : string, val : s32) -> bool
{
	param, ok := get_shader_parameter (shader, name);
	if !ok || param.kind != .S32
		return false;
	glUniform1i (param.location, val);

	return true;
}

set_shader_parameter :: inline (shader : *Shader, name : string, val : u32) -> bool
{
	param, ok := get_shader_parameter (shader, name);
	if !ok || param.kind != .U32
		return false;
	glUniform1ui (param.location, val);

	return true;
}

set_shader_parameter :: inline (shader : *Shader, name : string, val : f32) -> bool
{
	param, ok := get_shader_parameter (shader, name);
	if !ok || param.kind != .F32
		return false;
	glUniform1f (param.location, val);

	return true;
}

set_shader_parameter :: inline (shader : *Shader, name : string, val : Vec2f) -> bool
{
	param, ok := get_shader_parameter (shader, name);
	if !ok || param.kind != .VEC2F
		return false;
	glUniform2f (param.location, val.x, val.y);

	return true;
}

set_shader_parameter :: inline (shader : *Shader, name : string, val : Vec3f) -> bool
{
	param, ok := get_shader_parameter (shader, name);
	if !ok || param.kind != .VEC3F
		return false;
	glUniform3f (param.location, val.x, val.y, val.z);

	return true;
}

set_shader_parameter :: inline (shader : *Shader, name : string, val : Vec4f) -> bool
{
	param, ok := get_shader_parameter (shader, name);
	if !ok || param.kind != .VEC4F
		return false;
	glUniform4f (param.location, val.x, val.y, val.z, val.w);

	return true;
}

set_shader_parameter :: inline (shader : *Shader, name : string, val : Mat3f) -> bool
{
	param, ok := get_shader_parameter (shader, name);
	if !ok || param.kind != .MAT3F
		return false;
	glUniformMatrix3fv (param.location, 1, GL_TRUE, *val.r0c0);

	return true;
}

set_shader_parameter :: inline (shader : *Shader, name : string, val : Mat4f) -> bool
{
	param, ok := get_shader_parameter (shader, name);
	if !ok || param.kind != .MAT4F
		return false;
	glUniformMatrix4fv (param.location, 1, GL_TRUE, *val.r0c0);

	return true;
}
