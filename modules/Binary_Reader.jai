Binary_Reader :: struct
{
	start, cursor, end : *u8;
}

read :: inline ($T : Type, using reader : *Binary_Reader) -> value : T, ok : bool
{
	result : T;
	if cursor + size_of (T) > end
		return result, false;
	result = <<cast (*T) cursor;
	cursor += size_of (T);

	return result, true;
}

read_positive :: inline ($T : Type, using reader : *Binary_Reader) -> value : T, ok : bool
{
	value, ok := read (T, reader);
	if !ok || value < 0
		return 0, false;
	return value, true;
}

match_string :: (reader : *Binary_Reader, str : string, location := #caller_location) #expand
{
	if reader.cursor + str.count > reader.end
		`return log_error ("Expected '%', but there was not enough bytes (got %).", reader.end - reader.cursor, location = location);
	if memcmp (reader.cursor, str.data, str.count) != 0
		`return log_error ("Expected '%'.", str, location = location);
	reader.cursor += str.count;
}

expect :: (T : Type, reader : *Binary_Reader, location := #caller_location) -> T #expand
{
	val, ok := read (T, reader);
	if !ok
		`return log_error ("Expected %, but there was not enough bytes (got %, expected at least % bytes).", T, reader.end - reader.cursor, size_of (T), location = location);

	return val;
}

expect_positive :: (T : Type, reader : *Binary_Reader, location := #caller_location) -> T #expand
{
	val, ok := read (T, reader);
	if !ok
		`return log_error ("Expected %, but there was not enough bytes (got %, expected at least % bytes).", T, reader.end - reader.cursor, size_of (T), location = location);
	if val < 0
		`return log_error ("Expected a positive %, but got a negative value (%).", T, val, location = location);

	return val;
}

expect_string :: (reader : *Binary_Reader, count_type := s64, location := #caller_location) -> string #expand
{
	result : string;
	result.count = expect_positive (count_type, reader, location);
	if reader.cursor + result.count > reader.end
		`return log_error (
			"Expected a sequence of % characters, but there was not enough bytes (got %, expected at least % bytes).",
			result.count, reader.end - reader.cursor, result.count, location = location
		);
	result.data = reader.cursor;
	reader.cursor += result.count;

	return result;
}

expect_array :: (T : Type, reader : *Binary_Reader, count_type := s64, location := #caller_location) -> []T #expand
{
	result : []T;
	result.count = expect_positive (count_type, reader, location);
	if reader.cursor + size_of (T) * result.count > reader.end
		`return log_error (
			"Expected a sequence of % %s, but there was not enough bytes (got %, expected at least % bytes).",
			result.count, T, reader.end - reader.cursor, size_of (T) * result.count, location = location
		);
	result.data = cast (*T) reader.cursor;
	reader.cursor += size_of (T) * result.count;

	return result;
}
