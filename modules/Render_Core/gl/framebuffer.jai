Framebuffer :: struct
{
	Binding :: struct
	{
		fbo : GLuint;
	}

	using binding : Binding;
}

init_framebuffer :: inline (framebuffer : *Framebuffer, color_texture : *Texture) -> bool
{
	glGenFramebuffers (1, *framebuffer.fbo);
	glBindFramebuffer (GL_FRAMEBUFFER, framebuffer.fbo);
	defer glBindFramebuffer (GL_FRAMEBUFFER, 0);
	glFramebufferTexture2D (GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, color_texture.tex, 0);

	status := glCheckFramebufferStatus (GL_FRAMEBUFFER);
	if status != GL_FRAMEBUFFER_COMPLETE
	{
		glDeleteFramebuffers (1, *framebuffer.fbo);
		framebuffer.fbo = 0;

		return false;
	}

	return true;
}

destroy_framebuffer :: inline (framebuffer : *Framebuffer)
{
	glDeleteFramebuffers (1, *framebuffer.fbo);
	framebuffer.fbo = 0;
}

get_current_draw_framebuffer :: inline () -> Framebuffer.Binding #must
{
	fbo : s32;
	glGetIntegerv (GL_DRAW_FRAMEBUFFER_BINDING, *fbo);
	result : Framebuffer.Binding = ---;
	result.fbo = xx fbo;

	return result;
}

get_current_read_framebuffer :: inline () -> Framebuffer.Binding #must
{
	fbo : s32;
	glGetIntegerv (GL_READ_FRAMEBUFFER_BINDING, *fbo);
	result : Framebuffer.Binding = ---;
	result.fbo = xx fbo;

	return result;
}

use_framebuffer_for_drawing :: inline (binding : *Framebuffer.Binding) -> previous : Framebuffer.Binding
{
	previous := get_current_draw_framebuffer ();
	if binding
		glBindFramebuffer (GL_DRAW_FRAMEBUFFER, binding.fbo);
	else
		glBindFramebuffer (GL_DRAW_FRAMEBUFFER, 0);

	return previous;
}

use_framebuffer_for_reading :: inline (binding : *Framebuffer.Binding) -> previous : Framebuffer.Binding
{
	previous := get_current_read_framebuffer ();
	if binding
		glBindFramebuffer (GL_READ_FRAMEBUFFER, binding.fbo);
	else
		glBindFramebuffer (GL_READ_FRAMEBUFFER, 0);

	return previous;
}
