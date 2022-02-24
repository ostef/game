#import "Win32";

open_file :: inline (filename : string, flags : File_Open_Flags, attributes := File_Attributes.NORMAL) -> *File #must
{
	access, share_mode : DWORD;
	if flagged (flags, .ACCESS_READ)
	{
		access |= GENERIC_READ;
		share_mode |= FILE_SHARE_READ;
	}
	if flagged (flags, .ACCESS_WRITE)
	{
		access |= GENERIC_WRITE;
		share_mode |= FILE_SHARE_WRITE;
	}
	open_mode : DWORD;
	if flagged (flags, .OPEN_IF_EXISTS)
		open_mode = OPEN_EXISTING;
	else if flagged (flags, .OPEN_OR_CREATE)
		open_mode = OPEN_ALWAYS;
	else if flagged (flags, .ALWAYS_CREATE)
		open_mode = CREATE_ALWAYS;
	file := CreateFileW (
		win32_utf8_to_wide (filename, TEMP_ALLOC),
		access,
		share_mode,
		null,
		open_mode,
		win32_from_file_attributes (attributes),
		null
	);
	if file == INVALID_HANDLE_VALUE
		return null;
	
	return cast (*File) file;
}

close_file :: inline (file : *File) -> bool
{
	return CloseHandle (file) != 0;
}

delete_file :: inline (filename : string) -> bool
{
	return DeleteFileW (win32_utf8_to_wide (filename, TEMP_ALLOC)) != 0;
}

move_file :: inline (src_filename : string, dst_filename : string) -> bool
{
	return MoveFileW (
		win32_utf8_to_wide (src_filename, TEMP_ALLOC),
		win32_utf8_to_wide (dst_filename, TEMP_ALLOC)
	) != 0;
}

get_file_cursor :: inline (file : *File) -> offset : s64 #must
{
	offset := SetFilePointer (file, 0, null, FILE_CURRENT);

	return cast (s64) offset;
}

set_file_cursor :: inline (file : *File, offset : s64, base := File_Cursor.BEGIN) -> moved : s64, ok : bool
{
	win32_cursor : DWORD;
	if #complete base ==
	{
	case .BEGIN;   win32_cursor = FILE_BEGIN;
	case .END;     win32_cursor = FILE_END;
	case .CURRENT; win32_cursor = FILE_CURRENT;
	}
	moved := SetFilePointer (file, xx offset, null, win32_cursor);

	return cast (s64) moved, moved != INVALID_SET_FILE_POINTER;
}

set_eof_to_cursor :: inline (file : *File) -> bool
{
	return SetEndOfFile (file) != 0;
}

read_file :: inline (file : *File, buffer : *void, size : s64) -> read : s64, ok : bool
{
	read : u32;
	ok := ReadFile (file, buffer, xx size, *read, null);

	return cast (s64) read, ok != 0;
}

write_file :: inline (file : *File, buffer : *void, size : s64) -> written : s64, ok : bool
{
	written : u32;
	ok := WriteFile (file, buffer, xx size, *written, null);

	return cast (s64) written, ok != 0;
}

file_exists :: inline (filename : string) -> bool #must
{
	return GetFileAttributesW (win32_utf8_to_wide (filename, TEMP_ALLOC)) != INVALID_FILE_ATTRIBUTES;
}

win32_to_file_attributes :: inline (win32_attrs : DWORD) -> File_Attributes #must
{
	result : File_Attributes;
	if flagged (win32_attrs, FILE_ATTRIBUTE_DIRECTORY)
		result |= .DIRECTORY;
	if flagged (win32_attrs, FILE_ATTRIBUTE_HIDDEN)
		result |= .HIDDEN;
	if flagged (win32_attrs, FILE_ATTRIBUTE_READONLY)
		result |= .READ_ONLY;
	if flagged (win32_attrs, FILE_ATTRIBUTE_REPARSE_POINT)
		result |= .SYMLINK;
	if flagged (win32_attrs, FILE_ATTRIBUTE_TEMPORARY)
		result |= .TEMPORARY;

	return result;
}

win32_from_file_attributes :: inline (attributes : File_Attributes) -> DWORD #must
{
	win32_attrs : DWORD;
	if flagged (attributes, .DIRECTORY)
		win32_attrs |= FILE_ATTRIBUTE_DIRECTORY;
	if flagged (attributes, .HIDDEN)
		win32_attrs |= FILE_ATTRIBUTE_HIDDEN;
	if flagged (attributes, .READ_ONLY)
		win32_attrs |= FILE_ATTRIBUTE_READONLY;
	if flagged (attributes, .SYMLINK)
		win32_attrs |= FILE_ATTRIBUTE_REPARSE_POINT;
	if flagged (attributes, .TEMPORARY)
		win32_attrs |= FILE_ATTRIBUTE_TEMPORARY;
		
	return win32_attrs;
}

get_file_attributes :: inline (filename : string) -> File_Attributes, exists : bool
{
	win32_attrs := GetFileAttributesW (win32_utf8_to_wide (filename, TEMP_ALLOC));
	if win32_attrs == INVALID_FILE_ATTRIBUTES
		return 0, false;

	return win32_to_file_attributes (win32_attrs), true;
}

set_file_attributes :: inline (filename : string, attributes : File_Attributes) -> bool
{
	remove_flag (*attributes, .DIRECTORY);
	remove_flag (*attributes, .SYMLINK);

	return SetFileAttributesW (win32_utf8_to_wide (filename, TEMP_ALLOC), win32_from_file_attributes (attributes)) != 0;
}

create_directory :: inline (dirname : string) -> bool
{
	return CreateDirectoryW (win32_utf8_to_wide (dirname, TEMP_ALLOC), null) != 0;
}

delete_empty_directory :: inline (dirname : string) -> bool
{
	return RemoveDirectoryW (win32_utf8_to_wide (dirname, TEMP_ALLOC)) != 0;
}

get_working_directory :: inline (allocator : Allocator) -> string #must
{
	length := GetCurrentDirectoryW (0, null);
	buffer := alloc (2 * (length + 1), TEMP_ALLOC);
	GetCurrentDirectoryW (length + 1, buffer);

	return win32_wide_to_utf8 (buffer, allocator);}
}

set_working_directory :: inline (dirname : string) -> bool
{
	return SetCurrentDirectoryW (win32_utf8_to_wide (dirname, TEMP_ALLOC)) != 0;
}

#scope_file

list_files_helper :: (dirname : string, recursive : bool, parent_index : s64, all_files : *[..]File_Info) -> bool
{
	wildcard := win32_utf8_to_wide (join (TEMP_ALLOC, dirname, "/*"), TEMP_ALLOC);
	find_data : WIN32_FIND_DATAW = ---;
	find_handle := FindFirstFileW (wildcard, *find_data);
	if find_handle == INVALID_HANDLE_VALUE
		return log_error ("FindFirstFileW failed: %", win32_get_last_error_string ());
	defer FindClose (find_handle);

	prev_sibling_index := -1;
	while true
	{
		utf8_name := win32_wide_to_utf8 (find_data.cFileName.data, TEMP_ALLOC);
		is_root := utf8_name == ".";
		// Include the root directory '.' if parent is null, because we return
		// the root in list_files_in_directory. Otherwise ignore it.
		if is_root && parent_index < 0 || utf8_name != "." && utf8_name != ".."
		{
			if all_files.count == 0 then assert (is_root, "The first visited file should be the root, but it was '%'.", utf8_name);

			file_info := push_into_array (all_files);
			file_info.name = clone_string (utf8_name, all_files.allocator);
			file_info.full_name = join (all_files.allocator, dirname, "/", file_info.name);
			file_info.attributes = win32_to_file_attributes (find_data.dwFileAttributes);
			file_info.size   = (cast (s64) find_data.nFileSizeHigh << 32) | cast (s64) find_data.nFileSizeLow;
			file_info.parent = ifx parent_index > -1 then *all_files.data[parent_index] else null;
			file_info.prev_sibling = ifx parent_index > -1 then *all_files.data[prev_sibling_index] else null;
			
			if prev_sibling_index > -1
				all_files.data[prev_sibling_index].next_sibling = file_info;
			else if parent_index > -1
				all_files.data[parent_index].first_child = file_info;

			if is_root then parent_index = all_files.count - 1;
			else prev_sibling_index = all_files.count - 1;

			if recursive && flagged (file_info.attributes, .DIRECTORY) && file_info.name != "."
				file_info.has_errors = !list_files_helper (file_info.full_name, recursive, all_files.count - 1, all_files);
		}

		if !FindNextFileW (find_handle, *find_data) then break;
	}

	return true;
}

#scope_export

// @Note (stefan): The File_Infos are allocated contiguously, and the first File_Info is also the root.
// This means you can ignore the all_files array, and only care about the root when you have to free the
// allocated File_Infos.
list_files_in_directory :: inline (dirname : string, recursive : bool, allocator : Allocator) -> root : *File_Info #must, all_files : []File_Info
{
	all_files : [..]File_Info;
	all_files.allocator = allocator;
	ok := list_files_helper (dirname, recursive, -1, *all_files);
	if !ok
	{
		reset_array (*all_files);

		return null, all_files;
	}

	return *all_files[0], all_files;
}

delete_directory :: (dirname : string) -> bool
{
	temporary_block ();
	root := list_files_in_directory (dirname, false, TEMP_ALLOC);
	if !root
		return false;
	for root
	{
		if flagged (it.attributes, .DIRECTORY)
			delete_directory (it.full_name);
		else
			delete_file (it.full_name);
	}

	return delete_empty_directory (dirname);
}
