read_bytes_as_u32_be :: inline (bytes : *[]u8) -> val : u32, ok : bool
{
	if bytes.count < 4
		return 0, false;
	// @Endianness (stefan): We assume we are on a little-endian machine.
	val := (cast (u32) bytes.data[0]
		| (cast (u32) (bytes.data[1]) << 8)
		| (cast (u32) (bytes.data[2]) << 16)
		| (cast (u32) (bytes.data[3]) << 24)
	);
	bytes.data  += 4;
	bytes.count -= 4;

	return val, true;
}

read_bytes_as_u32_le :: inline (bytes : *[]u8) -> val : u32, ok : bool
{
	if bytes.count < 4
		return 0, false;
	// @Endianness (stefan): We assume we are on a little-endian machine.
	val := (cast (u32) bytes.data[3]
		| (cast (u32) (bytes.data[2]) << 8)
		| (cast (u32) (bytes.data[1]) << 16)
		| (cast (u32) (bytes.data[0]) << 24)
	);
	bytes.data  += 4;
	bytes.count -= 4;

	return val, true;
}

read_bytes_as_u8 :: inline (bytes : *[]u8) -> val : u8, ok : bool
{
	if bytes.count < 1
		return 0, false;
	val := bytes.data[0];
	bytes.data  += 1;
	bytes.count -= 1;

	return val, true;
}
