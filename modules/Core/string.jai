make_string :: inline (data : *u8, count : s64) -> string #must
{
	result : string = ---;
	result.data  = data;
	result.count = count;

	return result;
}

to_array :: inline (str : string) -> []u8 #must
{
	result : []u8 = ---;
	result.data = str.data;
	result.count = str.count;

	return result;
}

clone_string :: inline (str : string, allocator : Allocator) -> string #must
{
	result : string = ---;
	result.data = alloc (str.count, allocator);
	memcpy (result.data, str.data, str.count);
	result.count = str.count;

	return result;
}

clone_to_cstring :: inline (str : string, allocator : Allocator) -> *u8 #must
{
	result : *u8 = ---;
	result = alloc (str.count + 1, allocator);
	memcpy (result, str.data, str.count);
	result[str.count] = 0;

	return result;
}

to_string :: inline (array : []u8) -> string #must
	#no_context
{
	result : string = ---;
	result.data = array.data;
	result.count = array.count;

	return result;
}

is_digit :: inline (codepoint : u32) -> bool #must
	#no_context
{
	return codepoint >= #char "0" && codepoint <= #char "9";
}

is_alpha :: inline (codepoint : u32) -> bool #must
	#no_context
{
	return codepoint >= #char "a" && codepoint <= #char "z" ||
		codepoint >= #char "A" && codepoint <= #char "Z";
}

is_upper :: inline (codepoint : u32) -> bool #must
	#no_context
{
	return codepoint >= #char "A" && codepoint <= #char "Z";
}

is_lower :: inline (codepoint : u32) -> bool #must
	#no_context
{
	return codepoint >= #char "a" && codepoint <= #char "z";
}

is_ascii :: inline (codepoint : u32) -> bool #must
	#no_context
{
	return codepoint >= 0 && codepoint <= 127;
}

advance :: inline (val : string, count := 1) -> string #must
	#no_context
{
	count = clamp (count, 0, val.count);
	result : string = ---;
	result.data  = val.data + count;
	result.count = val.count - count;

	return result;
}

compare_strings :: inline (str1 : string, str2 : string) -> int #must
	#no_context
	#no_abc
{
	i := 0;
	while i < str1.count && i < str2.count && str1[i] == str2[i]
		i += 1;
	if i == str1.count && i == str2.count
		return 0;
	else if i == str1.count
		return -cast (s64) str2[i];
	else if i == str2.count
		return cast (s64) str1[i];
	return cast (s64) str1[i] - cast (s64) str2[i];
}

starts_with :: inline (str : string, with : string) -> bool #must
	#no_context
{
	if str.count < with.count
		return false;
	str1 : string = ---;
	str1.data = str.data;
	str1.count = with.count;

	return compare_strings (str1, with) == 0;
}

join :: inline (allocator : Allocator, args : ..string) -> string #must
{
	total_size := 0;
	for args
		total_size += it.count;
	if total_size == 0
		return "";
	result : string = ---;
	result.data = alloc (total_size, allocator);
	if !result.data
		return "";
	result.count = total_size;
	i := 0;
	for args
	{
		memcpy (result.data + i, it.data, it.count);
		i += it.count;
	}

	return result;
}
