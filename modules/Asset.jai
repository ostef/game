#import "Core";
#import "Storage";
#import "Hash_Map";
#import "Binary_Reader";

Asset :: struct (T : Type)
{
	name : string;
	ref_count : s64;
	using data : T;
}

Asset_Cache :: struct (T : Type)
{
	Asset_Type :: Asset (T);
	Load_Func    :: #type (*T, string) -> bool;
	Cleanup_Func :: #type (*T);

	storage      : Storage (Asset_Type, 20);
	lookup_table : Hash_Map (string, *Asset_Type);
	load_func    : Load_Func;
	cleanup_func : Cleanup_Func;
}

init_asset_cache :: inline (cache : *Asset_Cache, load_func : cache.Load_Func, cleanup_func : cache.Cleanup_Func)
{
	init_storage (*cache.storage, HEAP_ALLOC);
	init_map (*cache.lookup_table, 100, HEAP_ALLOC);
	cache.load_func    = load_func;
	cache.cleanup_func = cleanup_func;
}

add_ref :: inline (using asset : *$T/Asset) -> *T
{
	ref_count += 1;

	return asset;
}

load_asset :: (using cache : *Asset_Cache, name : string) -> *cache.Asset_Type #must
{
	asset := get_value (lookup_table, name, null);
	if asset
		return add_ref (asset);
	asset = find_free_slot (*storage);
	asset.name = name;
	ok := load_func (asset, name);
	if !ok
	{
		log_error ("Could not load asset '%'.", name);
		cleanup_func (asset);
		release_slot (*storage, asset);

		return null;
	}
	asset.name = clone_string (name, HEAP_ALLOC);
	insert_into_map (*lookup_table, asset.name, asset);

	return add_ref (asset);
}

release_asset :: (using cache : *Asset_Cache, asset : *cache.Asset_Type)
{
	assert (asset.ref_count > 0, "Releasing asset '%' but it has no reference.", asset.name);
	asset.ref_count -= 1;
	if asset.ref_count == 0
	{
		log_message ("Unloading asset '%'.", asset.name);
		if cleanup_func
			cleanup_func (asset);
		release_slot (*storage, asset);
		remove_from_map (*lookup_table, asset.name);
		free (asset.name, HEAP_ALLOC);
	}
}

Format_Version :: struct
{
	major, minor, micro : u32;
}

operator < :: inline (left : Format_Version, right : Format_Version) -> bool #must
{
	return left.major < right.major || left.minor < right.minor || left.micro < right.micro;
}

Asset_Version :: struct
{
	day, month, year : u32;
	hours, minutes, seconds : u8;
}

operator < :: inline (left : Asset_Version, right : Asset_Version) -> bool #must
{
	return left.year < right.year
		|| left.month < right.month
		|| left.day < right.day
		|| left.hours < right.hours
		|| left.minutes < right.minutes
		|| left.seconds < right.seconds;
}

expect_asset_header :: (
	reader : *Binary_Reader,
	format_identifier : string
) ->
	Format_Version,
	Asset_Version
#expand
{
	match_string (reader, format_identifier);
	match_string (reader, "\n");
	using format_version : Format_Version;
	using asset_version  : Asset_Version;
	bytes_read : s64;
	major, bytes_read = string_to_u32 (to_string (reader));
	if !bytes_read
		`return log_error ("Expected a u32, for Format_Version.major.");
	reader.cursor += bytes_read;
	match_string (reader, ".");
	minor, bytes_read = string_to_u32 (to_string (reader));
	if !bytes_read
		`return log_error ("Expected a u32, for Format_Version.minor.");
	reader.cursor += bytes_read;
	match_string (reader, ".");
	micro, bytes_read = string_to_u32 (to_string (reader));
	if !bytes_read
		`return log_error ("Expected a u32, for Format_Version.micro.");
	reader.cursor += bytes_read;
	match_string (reader, "\n");
	year, bytes_read = string_to_u32 (to_string (reader));
	if !bytes_read
		`return log_error ("Expected a u32, for Asset_Version.year.");
	reader.cursor += bytes_read;
	match_string (reader, ":");
	month, bytes_read = string_to_u32 (to_string (reader));
	if !bytes_read
		`return log_error ("Expected a u32, for Asset_Version.month.");
	if month > 12
		`return log_error ("Expected a u8 less than 13 for Asset_Version.month, got %.", month);
	reader.cursor += bytes_read;
	match_string (reader, ":");
	day, bytes_read = string_to_u32 (to_string (reader));
	if !bytes_read
		`return log_error ("Expected a u32, for Asset_Version.day.");
	if day > 31
		`return log_error ("Expected a u8 less than 31 for Asset_Version.day, got %.", day);
	reader.cursor += bytes_read;
	match_string (reader, ".");
	hours, bytes_read = string_to_u8 (to_string (reader));
	if !bytes_read
		`return log_error ("Expected a u8, for Asset_Version.hours.");
	if hours > 23
		`return log_error ("Expected a u8 less than 24 for Asset_Version.hours, got %.", hours);
	reader.cursor += bytes_read;
	match_string (reader, ":");
	minutes, bytes_read = string_to_u8 (to_string (reader));
	if !bytes_read
		`return log_error ("Expected a u8, for Asset_Version.minutes.");
	if minutes > 59
		`return log_error ("Expected a u8 less than 60 for Asset_Version.minutes, got %.", minutes);
	reader.cursor += bytes_read;
	match_string (reader, ":");
	seconds, bytes_read = string_to_u8 (to_string (reader));
	if !bytes_read
		`return log_error ("Expected a u8, for Asset_Version.seconds.");
	if seconds > 59
		`return log_error ("Expected a u8 less than 60 for Asset_Version.seconds, got %.", seconds);
	reader.cursor += bytes_read;
	match_string (reader, "\n");

	return format_version, asset_version;
}
