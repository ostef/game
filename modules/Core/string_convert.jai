string_to_u64 :: inline (str : string) -> value : u64 #must, bytes_read : s64
{
	i := 0;
	result : u64;
	while i < str.count && is_digit (str[i])
	{
		result *= 10;
		result += cast (u64) str[i] - #char "0";
		i += 1;
	}

	return result, i;
}

string_to_u32 :: inline (str : string) -> value : u32 #must, bytes_read : s64
{
	val, read := string_to_u64 (str);

	return cast (u32) val, read;
}

string_to_u16 :: inline (str : string) -> value : u16 #must, bytes_read : s64
{
	val, read := string_to_u64 (str);

	return cast (u16) val, read;
}

string_to_u8 :: inline (str : string) -> value : u8 #must, bytes_read : s64
{
	val, read := string_to_u64 (str);

	return cast (u8) val, read;
}

string_to_s64 :: inline (str : string) -> value : s64 #must, bytes_read : s64
{
	if str.count == 0 then return 0, 0;

	i := 0;
	sign := 1;
	if str[0] == #char "-" || str[0] == #char "+"
	{
		sign = cast (s64) (str[0] == #char "+") * 2 - 1;
		i += 1;
	}
	unsigned_value, bytes_read := string_to_u64 (advance (str, i));
	if bytes_read == 0 then return 0, 0;
	signed_value := sign * cast (s64) unsigned_value;

	return signed_value, i + bytes_read;
}

string_to_s32 :: inline (str : string) -> value : s32 #must, bytes_read : s64
{
	val, read := string_to_s64 (str);

	return cast (s32) val, read;
}

string_to_s16 :: inline (str : string) -> value : s16 #must, bytes_read : s64
{
	val, read := string_to_s64 (str);

	return cast (s16) val, read;
}

string_to_s8 :: inline (str : string) -> value : s8 #must, bytes_read : s64
{
	val, read := string_to_s64 (str);

	return cast (s8) val, read;
}

#scope_file

ryu :: #import "Ryu" (IMPORT_FLOAT_TO_SHORTEST = false, IMPORT_FLOAT_TO_FIXED_AND_EXP = false);

#scope_export

string_to_f32 :: inline (str : string) -> value : f32 #must, bytes_read : s64
{
	value, status, bytes_read := ryu.string_to_f32 (str);
	if status != .SUCCESS
		return 0.0, 0;

	return value, bytes_read;
}

string_to_f64 :: inline (str : string) -> value : f64 #must, bytes_read : s64
{
	value, status, bytes_read := ryu.string_to_f64 (str);
	if status != .SUCCESS
		return 0.0, 0;

	return value, bytes_read;
}
