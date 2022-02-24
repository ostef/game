#import "Core";
#import "File_System";

#load "read_bytes.jai";
#load "deflate.jai";

PNG_MAGIC_NUMBER :: u8.[ 0x89, #char "P", #char "N", #char "G", 0x0d, 0x0a, 0x1a, 0x0a ];

Image :: struct
{
	data     : *void;
	width    : u32;
	height   : u32;
	channels : u32;
}

PNG_Color_Type :: enum u8
{
	GRAYSCALE :: 0;
	TRUECOLOR :: 2;
	INDEXED   :: 3;
	GRAYSCALE_ALPHA :: 4;
	TRUECOLOR_ALPHA :: 6;
}

PNG_Image_Header :: struct
{
	image_width  : u32;
	image_height : u32;
	bit_depth : u8;	// Must be 1, 2, 4, 8 or 16
	color_type : PNG_Color_Type;
	compression_method : u8;	// Must be 0
	filter_method : u8;	// Must be 0
	interlace_method : u8;	// Must be 0 or 1
}

detect_png :: inline (buffer : []u8) -> bool #must
	#no_abc
{
	if buffer.count < PNG_MAGIC_NUMBER.count
		return false;
	return buffer[0] == PNG_MAGIC_NUMBER[0] &&
		buffer[1] == PNG_MAGIC_NUMBER[1] &&
		buffer[2] == PNG_MAGIC_NUMBER[2] &&
		buffer[3] == PNG_MAGIC_NUMBER[3] &&
		buffer[4] == PNG_MAGIC_NUMBER[4] &&
		buffer[5] == PNG_MAGIC_NUMBER[5] &&
		buffer[6] == PNG_MAGIC_NUMBER[6] &&
		buffer[7] == PNG_MAGIC_NUMBER[7];
}

png_ancillary_chunk_is_handled :: inline (type : string) -> bool #must
{
	return false;
}

load_png :: (buffer : []u8, out : *Image) -> bool
	#no_abc
{
	cur := buffer;
	if !detect_png (cur)
		return log_error ("Not a PNG file.");
	cur = advance (cur, PNG_MAGIC_NUMBER.count);

	CHUNK_MIN_SIZE :: 4 + 4 + 4;	// 4 bytes for length, 4 bytes for type, 4 bytes for CRC
	// Read chunks
	chunk_index := 0;
	ihdr : PNG_Image_Header;
	found_plte_chunk := false;
	found_idat_chunk := false;
	found_iend_chunk := false;
	prev_chunk_was_idat := false;
	while cur.count >= CHUNK_MIN_SIZE
	{
		defer chunk_index += 1;
		length := read_bytes_as_u32_be (*cur);
		type := make_string (cur.data, 4);
		cur = advance (cur, 4);
		if length + 4 > cur.count
			return log_error ("Chunk % (%) has a length larger than the buffer.", chunk_index, type);
		is_critical := is_upper (type[0]);
		if length > cast (u32) S32_MAX
		{
			if is_critical
				return log_error ("Critical chunk %: length is larger than maximum allowed.", chunk_index);
			cur = advance (cur, cast (s64) length + 4);	// Skip data and CRC
			log_warning ("Ancillary chunk %: length is larger than maximum allowed. Ignoring chunk.", chunk_index);

			continue;
		}
		// The first chunk has to be an image header critical chunk
		if chunk_index == 0 && type != "IHDR"
			return log_error ("First chunk is %, should be IHDR.", type);
		if type ==
		{
		case "IHDR";
			if chunk_index != 0
				return log_error ("Chunk % is IHDR, but there should be only one IHDR chunk at index 0.", chunk_index);
			if !read_png_image_header (cur, length, *ihdr)
				return log_error ("Could not read IHDR chunk.");

		case "PLTE";
			if ihdr.color_type == .GRAYSCALE || ihdr.color_type == .GRAYSCALE_ALPHA
				return log_error ("Found a PLTE chunk for color type %, which is not permitted.", ihdr.color_type);
			if found_plte_chunk
				return log_error ("Found multiple PLTE chunks. Only one is permitted.");
			found_plte_chunk = true;

		case "IDAT";
			if ihdr.color_type == .INDEXED && !found_plte_chunk
				return log_error ("Found an IDAT chunk but expected a PLTE chunk before, for color type %.", ihdr.color_type);
			if found_idat_chunk && !prev_chunk_was_idat
				return log_error ("Found an IDAT chunk after another chunk that is not IDAT. IDAT chunks must be consecutive.");
			found_idat_chunk = true;

		case "IEND";
			if length != 0
				return log_error ("Invalid chunk length for IEND chunk (expected 0, got %).", length);
			if cur.count > 4
				return log_error ("Found something after IEND chunk.");
			found_iend_chunk = true;

		case;
			if is_critical
				return log_error ("Could not read critical chunk: invalid chunk type.");
			cur = advance (cur, cast (s64) length + 4);	// Skip data and CRC
			log_warning ("Could not read ancillary chunk: unhandled chunk type. Ignoring chunk.");

			continue;
		}
		prev_chunk_was_idat = type == "IDAT";
		cur = advance (cur, cast (s64) length);
		crc := read_bytes_as_u32_be (*cur);
	}
	if !found_iend_chunk
		return log_error ("Did not find IEND chunk at end of buffer.");

	return true;
}

read_png_image_header :: inline (buffer : []u8, length : u32, using ihdr : *PNG_Image_Header) -> bool
{
	if length != 16
		return log_error ("Invalid length for IHDR chunk (expected 16, got %).", length);
	cur := buffer;
	image_width  = read_bytes_as_u32_be (*cur);
	image_height = read_bytes_as_u32_be (*cur);
	bit_depth = read_bytes_as_u8 (*cur);
	if bit_depth != 1 && bit_depth != 2 && bit_depth != 4 && bit_depth != 8 && bit_depth != 16
		return log_error ("Invalid bit depth for IHDR chunk (expected 1, 2, 4, 8 or 16, got %).", bit_depth);
	color_type = cast, no_check (PNG_Color_Type) read_bytes_as_u8 (*cur);
	if color_type != xx 0 && color_type != xx 2 && color_type != xx 3 && color_type != xx 4 && color_type != xx 6
		return log_error ("Invalid color type for IHDR chunk (expected 0, 2, 3, 4 or 6, got {:i}).", color_type);
	// Check if the bit depth is valid for the given color type
	if color_type == .INDEXED && bit_depth == 16
		return log_error ("Invalid bit depth for color type % (expected 1, 2, 4 or 8, got 16).", color_type);
	else if color_type != .GRAYSCALE && bit_depth != 8 && bit_depth != 16
		return log_error ("Invalid bit depth for color type % (expected 8 or 16, got %).", color_type, bit_depth);
	compression_method = read_bytes_as_u8 (*cur);
	if compression_method != 0
		return log_error ("Invalid compression method for IHDR chunk (expected 0, got %).", compression_method);
	filter_method = read_bytes_as_u8 (*cur);
	if filter_method != 0
		return log_error ("Invalid filter method for IHDR chunk (expected 0, got %).", filter_method);
	interlace_method = read_bytes_as_u8 (*cur);
	if interlace_method != 0 && interlace_method != 1
		return log_error ("Invalid interlace method for IHDR chunk (expected 0 or 1, got %).", interlace_method);

	return true;
}

read_png_palette :: inline (buffer : []u8, length : u32, using ihdr : PNG_Image_Header, palette : *[][3]u8) -> bool
{
	if length == 0 || length % 3 != 0
		return log_error ("Invalid length for PLTE chunk (expected a multiple of 3, larger than 0, got %).", length);
	count := length / 3;
	if color_type == .INDEXED && count > (1 << bit_depth) - 1
		return log_error ("Too many palette entries (expected at most %, got %).", (1 << bit_depth) - 1, count);
	palette.data = cast (*[3]u8) buffer.data;
	palette.count = count;

	return true;
}

read_png_image_data :: inline (buffer : []u8, length : u32, using ihdr : PNG_Image_Header) -> bool
{
	// Decompress
	// Unfilter
	// 
	return true;
}

load_png_from_file :: inline (filename : string, out : *Image) -> bool
{
	contents, ok := read_entire_file (filename, HEAP_ALLOC);
	if !ok
		return log_error ("Could not read file '%'.", filename);
	defer free (contents, HEAP_ALLOC);

	return load_png (to_array (contents), out);
}
