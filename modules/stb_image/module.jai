#module_parameters (STATIC_LINKING := true);

STBI_VERSION :: 1;

stbi_io_callbacks :: struct
{
	read : (user : *void, data : *u8, size : s32) -> s32;	// fill 'data' with 'size' bytes.  return number of bytes actually read
	skip : (user : *void, n : s32);	// skip the next 'n' bytes, or 'unget' the last -n bytes if negative
	eof  : (user : *void) -> s32;	// returns nonzero if we are at end of file/data
}

// 8-bits per channel

stbi_load_from_memory :: (
	buffer : *u8,
	len : s32,
	x : *s32,
	y : *s32,
	channels_in_file : *s32,
	desired_channels : s32
) -> *u8 #must #foreign stb_image;

stbi_load_from_callbacks :: (
	clbk : *stbi_io_callbacks,
	user : *void,
	x : *s32,
	y : *s32,
	channels_in_file : *s32,
	desired_channels : s32
) -> *u8 #must #foreign stb_image;

stbi_load :: (
	filename : *u8,
	x : *s32,
	y : *s32,
	channels_in_file : *s32,
	desired_channels : s32
) -> *u8 #must #foreign stb_image;

stbi_load_gif_from_memory :: (
	buffer : *u8,
	len : s32,
	delays : **s32,
	x : *s32,
	y : *s32,
	z : *s32,
	comp : *s32,
	req_comp : s32
) -> *u8 #must #foreign stb_image;

// 16-bits per channel

stbi_load_16_from_memory :: (
	buffer : *u8,
	len : s32,
	x : *s32,
	y : *s32,
	channels_in_file : *s32,
	desired_channels : s32
) -> *u16 #must #foreign stb_image;

stbi_load_16_from_callbacks :: (
	clbk : *stbi_io_callbacks,
	user : *void,
	x : *s32,
	y : *s32,
	channels_in_file : *s32,
	desired_channels : s32
) -> *u16 #must #foreign stb_image;

stbi_load_16 :: (
	filename : *u8,
	x : *s32,
	y : *s32,
	channels_in_file : *s32,
	desired_channels : s32
) -> *u16 #must #foreign stb_image;

// float per channel

stbi_loadf_from_memory :: (
	buffer : *u8,
	len : s32,
	x : *s32,
	y : *s32,
	channels_in_file : *s32,
	desired_channels : s32
) -> *float #must #foreign stb_image;

stbi_loadf_from_callbacks :: (
	clbk : *stbi_io_callbacks,
	user : *void,
	x : *s32,
	y : *s32,
	channels_in_file : *s32,
	desired_channels : s32
) -> *float #must #foreign stb_image;

stbi_loadf :: (
	filename : *u8,
	x : *s32,
	y : *s32,
	channels_in_file : *s32,
	desired_channels : s32
) -> *float #must #foreign stb_image;

stbi_is_hdr_from_callbacks :: (clbk : *stbi_io_callbacks, user : *void) -> s32 #foreign stb_image;
stbi_is_hdr_from_memory :: (buffer : *u8, len : s32) -> s32 #foreign stb_image;
stbi_is_hdr :: (filename : *u8) -> s32 #foreign stb_image;
stbi_failure_reason :: () -> *u8 #foreign stb_image;
stbi_image_free :: (retval_from_stbi_load : *void) #foreign stb_image;

stbi_info_from_callbacks :: (
	clbk : *stbi_io_callbacks,
	user : *void,
	x : *s32,
	y : *s32,
	comp : *s32
) -> s32 #foreign stb_image;

stbi_info_from_memory :: (
	buffer : *u8,
	len : s32,
	x : *s32,
	y : *s32,
	comp : *s32
) -> s32 #foreign stb_image;

stbi_info :: (
	filename : *u8,
	x : *s32,
	y : *s32,
	comp : *s32
) -> s32 #foreign stb_image;

stbi_is_16_bit_from_callbacks :: (clbk : *stbi_io_callbacks, user : *void) -> s32 #foreign stb_image;
stbi_is_16_bit_from_memory :: (buffer : *u8, len : s32) -> s32 #foreign stb_image;
stbi_is_16_bit :: (filename : *u8) -> s32 #foreign stb_image;
/*
stbi_set_unpremultiply_on_load :: (flag_true_if_should_unpremultiply : s32) #foreign stb_image;
stbi_convert_iphone_png_to_rgb :: (flag_true_if_should_convert : s32) #foreign stb_image;
stbi_set_flip_vertically_on_load :: (flag_true_if_should_flip : s32) #foreign stb_image;
stbi_set_unpremultiply_on_load_thread :: (flag_true_if_should_unpremultiply : s32) #foreign stb_image;
stbi_convert_iphone_png_to_rgb_thread :: (flag_true_if_should_convert : s32) #foreign stb_image;
stbi_set_flip_vertically_on_load_thread :: (flag_true_if_should_flip : s32) #foreign stb_image;
*/
stbi_zlib_decode_malloc_guesssize :: (
	buffer : *u8,
	len : s32,
	initial_size : s32,
	outlen : *s32
) -> *u8 #must #foreign stb_image;

stbi_zlib_decode_malloc_guesssize_headerflag :: (
	buffer : *u8,
	len : s32,
	initial_size : s32,
	outlen : *s32,
	parse_header : s32
) -> *u8 #must #foreign stb_image;

stbi_zlib_decode_malloc :: (
	buffer : *u8,
	len : s32,
	outlen : *s32
) -> *u8 #must #foreign stb_image;

stbi_zlib_decode_buffer :: (
	obuffer : *u8,
	olen : s32,
	ibuffer : *u8,
	ilen : s32
) -> *u8 #must #foreign stb_image;

stbi_zlib_decode_noheader_malloc :: (
	buffer : *u8,
	len : s32,
	outlen : *s32
) -> *u8 #must #foreign stb_image;

stbi_zlib_decode_noheader_buffer :: (
	obuffer : *u8,
	olen : s32,
	ibuffer : *u8,
	ilen : s32
) -> *u8 #must #foreign stb_image;

#if OS == .WINDOWS
{
#if STATIC_LINKING
	stb_image :: #foreign_library, no_dll "win/lib/stb_image";
else
	stb_image :: #foreign_library "win/dll/stb_image";
}
