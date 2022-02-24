Asset :: struct (T : Type)
{
	name : string;
	ref_count : s64;
	using data : T;
}

Format_Version :: struct
{
	major, minor, micro : u32;
}

Asset_Version :: struct
{
	day, month, year : u32;
	hours, minutes, seconds : u8;
}

expect_asset_header :: (
	reader : *Binary_Reader
	format_identifier : string
) ->
	format_version : Format_Version,
	asset_version : Asset_Version
#expand
{
	match_string (reader, #run join (TEMP_ALLOC, format_identifier, "\n"));

	return .{}, .{};
}

write_asset_header :: inline (
	writer : *Binary_Writer,
	format_identifier : string,
	format_version : Format_Version,
	asset_version : Asset_Version
)
{
	write_string (writer, format_identifier);
	write_string (writer, "\n");
	write_uint (writer, format_version.major);
	write_string (writer, ".");
	write_uint (writer, format_version.minor);
	write_string (writer, ".");
	write_uint (writer, format_version.micro);
	write_string (writer, "\n");
	write_uint (writer, asset_versionversion.year, 4);
	write_string (writer, ":");
	write_uint (writer, asset_versionversion.month, 2);
	write_string (writer, ":");
	write_uint (writer, asset_versionversion.day, 2);
	write_string (writer, ".");
	write_uint (writer, asset_versionversion.hours, 2);
	write_string (writer, ":");
	write_uint (writer, asset_versionversion.minutes, 2);
	write_string (writer, ":");
	write_uint (writer, asset_version.seconds, 2);
	write_string (writer, "\n");
}
