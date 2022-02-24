utf16_detect_byte_order :: inline (bom_mark : u16) -> matches_endianness : bool, valid : bool
{
	if bom_mark == 0xfeff
		return true, true;
	else if bom_mark == 0xfffe
		return false, true;
	return false, false;
}

utf16_decode :: inline (buffer : []u16) -> codepoint : u32, units_read : s64
#no_abc
{
	if buffer.count > 0
	{
		b0 := buffer[0];
		if b0 >= 0xd800 && b0 <= 0xdbff
		{
			if buffer.count < 2
				return UNICODE_INVALID, 1;
			b0 -= 0xd800;
			b0 *= 0x400;
			b1 := buffer[1];
			b1 -= 0xdc00;
			codepoint := cast (u32) (b0 + b1 + 0x10000);

			return codepoint, 2;
		}
		else if b0 <= 0xd7ff || (b0 >= 0xe000 && b0 <= 0xffff)
		{
			codepoint := cast (u32) b0;

			return codepoint, 1;
		}
	}
	return UNICODE_INVALID, 0;
}

utf16_encode :: inline (buffer : []u16, codepoint : u32) -> length : s64
#no_abc
{
	if codepoint <= 0xd7ff || (codepoint >= 0xe000 && codepoint <= 0xffff)
	{
		buffer[0] = cast (u16) codepoint;

		return 1;
	}
	else if codepoint > UNICODE_MAX || (codepoint >= 0xd800 && codepoint <= 0xdfff)
	{
		buffer[0] = cast (u16) UNICODE_INVALID;

		return 1;
	}
	else
	{
		codepoint -= 0x10000;
		buffer[0] = cast (u16) (0xd800 + (codepoint >> 10));
		buffer[1] = cast (u16) (0xdc00 + (codepoint & 0x03ff));


		return 2;
	}
}

utf16_encoding_length :: inline (codepoint : u32) -> s64 #must
{
	if codepoint <= 0xd7ff || (codepoint >= 0xe000 && codepoint <= 0xffff)
		return 1;
	else if codepoint > UNICODE_MAX || (codepoint >= 0xd800 && codepoint <= 0xdfff)
		return 1;
	else
		return 2;
}
