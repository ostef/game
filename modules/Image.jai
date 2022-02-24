#import "Core";
#import "stb_image";

Image :: struct
{
	data   : *void;
	width  : s32;
	height : s32;
	channels : s32;
}

load_image_from_file :: inline (image : *Image, filename : string, desired_channels : s32 = 0) -> bool
{
	width, height, channels : s32;
	data := stbi_load (clone_to_cstring (filename, TEMP_ALLOC), *width, *height, *channels, desired_channels);
	if !data
		return false;
	image.data = data;
	image.width = width;
	image.height = height;
	if desired_channels != 0
		image.channels = desired_channels;
	else
		image.channels = channels;

	return true;
}

load_image_from_memory :: inline (image : *Image, buffer : *void, size : s64, desired_channels : s32 = 0) -> bool
{
	width, height, channels : s32;
	data := stbi_load_from_memory (buffer, xx size, *width, *height, *channels, desired_channels);
	if !data
		return false;
	image.data = data;
	image.width = width;
	image.height = height;
	if desired_channels != 0
		image.channels = desired_channels;
	else
		image.channels = channels;

	return true;
}

destroy_image :: inline (image : *Image)
{
	stbi_image_free (image.data);
	image.data = null;
	image.width = 0;
	image.height = 0;
	image.channels = 0;
}
