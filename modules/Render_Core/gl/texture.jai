#import "Image";

Texture :: struct
{
	Binding :: struct
	{
		tex : GLuint;
	}

	using binding : Binding;
}

init_texture :: inline (texture : *Texture, width : u32, height : u32, channels : s32, data : *void) -> bool
{
	glGenTextures (1, *texture.tex);
	glBindTexture (GL_TEXTURE_2D, texture.tex);
	defer glBindTexture (GL_TEXTURE_2D, 0);
	source_format : GLenum;
	if channels ==
	{
	case 1; source_format = GL_RED;
	case 2; source_format = GL_RG;
	case 3; source_format = GL_RGB;
	case 4; source_format = GL_RGBA;
	case;
		log_error ("Invalid channel count for texture, expected 1, 2, 3 or 4, got %.", channels);

		return false;
	}
	if channels == 1 then glPixelStorei (GL_UNPACK_ALIGNMENT, 1);
	glTexImage2D (GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, source_format, GL_UNSIGNED_BYTE, data);
	if channels == 1 then glPixelStorei (GL_UNPACK_ALIGNMENT, 4);
	glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_BORDER);
	glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_BORDER);

	return true;
}

init_texture :: inline (texture : *Texture, image : *Image) -> bool
{
	return init_texture (texture, xx image.width, xx image.height, image.channels, image.data);
}

load_texture_from_file :: inline (texture : *Texture, filename : string) -> bool
{
	image : Image;
	if !load_image_from_file (*image, filename)
		return false;
	defer destroy_image (*image);

	return init_texture (texture, *image);
}

destroy_texture :: inline (texture : *Texture)
{
	glDeleteTextures (1, *texture.tex);
	texture.tex = 0;
}

get_current_texture :: inline (index : u32 = 0) -> Texture.Binding #must
{
	active : s32;
	glGetIntegerv (GL_ACTIVE_TEXTURE, *active);
	glActiveTexture (GL_TEXTURE0 + index);
	defer glActiveTexture (GL_TEXTURE0 + cast (u32) active);

	tex : s32;
	glGetIntegerv (GL_TEXTURE_BINDING_2D, *tex);
	result : Texture.Binding = ---;
	result.tex = xx tex;

	return result;
}

use_texture :: inline (binding : *Texture.Binding, index : u32 = 0) -> previous : Texture.Binding
{
	previous := get_current_texture (index);
	glActiveTexture (GL_TEXTURE0 + index);
	if binding
		glBindTexture (GL_TEXTURE_2D, binding.tex);
	else
		glBindTexture (GL_TEXTURE_2D, 0);

	return previous;
}
