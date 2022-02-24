decimal_length :: inline (value : $T, $$base : u64 = 10) -> s64 #must
	#no_context
{
	unsigned_value : u64;
	if value < 0
		unsigned_value = cast (u64) -value;
	else
		unsigned_value = cast (u64) value;
	length := 0;
	while unsigned_value > 0 || length == 0
	{
		unsigned_value /= base;
		length += 1;
	}
	if value < 0 then length += 1;

	return length;
}
