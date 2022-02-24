#import "Core";

#if OS == .WINDOWS
	#load "win32.jai";

File :: struct {}

File_Cursor :: enum
{
	BEGIN   :: 0;
	END     :: 1;
	CURRENT :: 2;
}

File_Open_Flags :: enum_flags
{
	OPEN_IF_EXISTS :: 0x01;
	OPEN_OR_CREATE :: 0x02;
	ALWAYS_CREATE  :: 0x03;
	
	ACCESS_READ  :: 0x10;
	ACCESS_WRITE :: 0x20;
}

File_Attributes :: enum_flags
{
	NORMAL    :: 0x00;
	DIRECTORY :: 0x01;
	HIDDEN    :: 0x02;
	READ_ONLY :: 0x04;
	SYMLINK   :: 0x08;
	TEMPORARY :: 0x10;
}

File_Info :: struct
{
	name : string;
	full_name : string;
	attributes : File_Attributes;
	size : s64;
	//creation_time
	//last_access_time
	//last_write_time
	has_errors : bool;
	
	// @Note (stefan): The *~s64 are relative pointers. This means
	// that the value of parent is relative to the address of parent in
	// memory. Because File_Infos are stored contiguously in an array
	// we can refer to other elements in the array from within elements
	// in the array using relative pointers, because the offset between
	// elements is always constant, and so pointers won't get invalidated
	// by the allocated memory being moved.
	parent : *~s64 File_Info;
	first_child  : *~s64 File_Info;
	prev_sibling : *~s64 File_Info;
	next_sibling : *~s64 File_Info;
}

for_expansion :: (info : *File_Info, body : Code, flags : For_Flags) #expand
{
	`it := info;
	`it_index := 0;
	while it
	{
		#insert body;
		if flagged (it.attributes, .DIRECTORY) && it.first_child
			it = it.first_child;
		else if it.next_sibling
			it = it.next_sibling;
		else
			it = it.parent;
		it_index += 1;
	}
}

children :: (info : *File_Info, body : Code, flags : For_Flags) #expand
{
	`it := info.first_child;
	`it_index := 0;
	while it
	{
		#insert body;
		it = it.next_sibling;
		it_index += 1;
	}
}

read_entire_file :: inline (filename : string, allocator : Allocator) -> string #must, ok : bool
{
	file := open_file (filename, File_Open_Flags.ACCESS_READ | .OPEN_IF_EXISTS);
	if !file
		return "", false;
	defer close_file (file);
	set_file_cursor (file, 0, .END);
	size := get_file_cursor (file);
	set_file_cursor (file, 0, .BEGIN);
	result : string = ---;
	result.data = alloc (size, allocator);
	if !result.data
		return "", false;
	result.count = size;
	read, ok := read_file (file, result.data, result.count);
	if !ok
	{
		free (result, allocator);

		return "", false;
	}

	return result, true;
}
