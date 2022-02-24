#import "Core";
#import "Fmt";
#import "Unicode";

String_Builder :: struct
{
	// Fmt uses this
	write_byte :: inline (builder : *String_Builder, byte : u8)
	{
		if builder
			print_byte_to_builder (builder, byte);
	}

	count : s64;
	data : *u8;
	allocated : s64;
	allocator : Allocator;
}

to_string :: inline (builder : String_Builder) -> string #must
{
	result : string = ---;
	result.data  = builder.data;
	result.count = builder.count;

	return result;
}

reset_builder :: inline (builder : *String_Builder)
{
	free (builder.data, builder.allocator);
	builder.data = null;
	builder.count = 0;
	builder.allocated = 0;
}

grow_builder :: inline (builder : *String_Builder, additional_capacity : s64)
{
	assert (builder.allocator.proc != null, "String builder is not initialized.");
	if additional_capacity <= 0
		return;
	new_capacity := builder.allocated + additional_capacity;
	new_data := realloc (builder.data, builder.allocated, new_capacity, builder.allocator);
	builder.data = new_data;
	builder.allocated = new_capacity;
}

print_byte_to_builder :: inline (builder : *String_Builder, byte : u8)
{
	if builder.count == builder.allocated
		grow_builder (builder, builder.allocated + 8);
	builder.data[builder.count] = byte;
	builder.count += 1;
}

print_char_to_builder :: inline (builder : *String_Builder, codepoint : u32)
{
	if builder.count == builder.allocated
		grow_builder (builder, builder.allocated + 8);
	utf8_sequence : [4]u8 = ---;
	utf8_length := utf8_encode (utf8_sequence, codepoint);
	for i : 0..utf8_length - 1
		builder.data[builder.count + i] = utf8_sequence[i];
	builder.count += utf8_length;
}

print_string_to_builder :: inline (builder : *String_Builder, str : string)
{
	for i : 0..str.count - 1
		print_char_to_builder (builder, str[i]);
}

print_f64_to_builder :: inline (builder : *String_Builder, value : f64, precision : u32 = 6)
{
	write_f64 (builder, value, precision);
}

print_u64_to_builder :: inline (builder : *String_Builder, value : u64, $$base := DECIMAL_BASE)
{
	write_u64 (builder, value, base = base);
}

print_s64_to_builder :: inline (builder : *String_Builder, value : s64, $$base := DECIMAL_BASE)
{
	write_s64 (builder, value, base = base);
}

print_location_to_builder :: inline (builder : *String_Builder, location : Source_Code_Location)
{
	print_string_to_builder (builder, location.fully_pathed_filename);
	print_string_to_builder (builder, ":");
	print_s64_to_builder (builder, location.line_number);
	print_string_to_builder (builder, ",");
	print_s64_to_builder (builder, location.character_number);
}

print_stack_trace_to_builder :: inline (builder : *String_Builder, node : *Stack_Trace_Node)
{
	while node
	{
		if node.info
		{
			print_to_builder (builder, "%:%: ", node.info.location.fully_pathed_filename, node.line_number);
			if node.info.name
				println_to_builder (builder, node.info.name);
			else
				println_to_builder (builder, "(anonymous procedure)");
		}
		node = node.next;
	}
}

print_to_builder :: inline (builder : *String_Builder, fmt_str : string, args : ..Any)
{
	fmt_buffered (builder, fmt_str, ..args);
}

println_to_builder :: inline (builder : *String_Builder, fmt_str : string, args : ..Any)
{
	print_to_builder (builder, fmt_str, ..args);
	print_to_builder (builder, "\n");
}
