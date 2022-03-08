// @Todo (stefan): Find a way to identify the module that logged the message.
// Maybe use the location, or we can have log_message be a macro, that looks
// up a variable called MODULE_NAME for example. But then, we won't be able
// to use external modules as-is. Can we check if an identifier is declared ?
// Can we insert that identifier for every module at module scope using a metaprogram ?

#scope_file

stdout_handle : HANDLE;
logger_critical_section : CRITICAL_SECTION;
logger_initialized : s32;

initialize_logger :: ()
{
	#import "Atomics";

	while true
	{
		if logger_initialized == 2
			break;
		ok, old := compare_and_swap (*logger_initialized, 0, 1);
		if old ==
		{
		case 0;
			InitializeCriticalSection (*logger_critical_section);
			stdout_handle = GetStdHandle (STD_OUTPUT_HANDLE);
			compare_and_swap (*logger_initialized, 1, 2);

		case 1;
			for 1..4
			#asm
			{
				pause;
				pause;
				pause;
				pause;
				pause;
			}
		}
	}
}

#scope_export

console_logger :: (message : string, data : *void, info : Log_Info)
{
	if message.count == 0
		return;
	initialize_logger ();
	if flagged (info.common_flags, .ERROR)
		SetConsoleTextAttribute (stdout_handle, FOREGROUND_RED);
	else if flagged (info.common_flags, .WARNING)
		SetConsoleTextAttribute (stdout_handle, FOREGROUND_RED | FOREGROUND_GREEN);
	WriteFile (stdout_handle, message.data, xx message.count, null, null);
	if message[message.count - 1] != #char "\n"
		WriteFile (stdout_handle, "\n".data, 1, null, null);
	SetConsoleTextAttribute (stdout_handle, FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_BLUE);
}

log_message :: inline (
	fmt_str : string,
	args : ..Any,
	flags := Log_Flags.NONE,
	user_flags : u32 = 0,
	location := #caller_location
)
{
	temporary_block ();
	//str := join (TEMP_ALLOC, "[", `MODULE_NAME, "] ", fmt (TEMP_ALLOC, fmt_str, ..args));
	str := fmt (HEAP_ALLOC, fmt_str, ..args);
	defer free (str, HEAP_ALLOC);
	if str.count == 0
		return;
	info : Log_Info;
	//info.source_identifier = `MODULE_NAME_HASH;
	info.location = location;
	info.common_flags = flags;
	info.user_flags = user_flags;
	context.logger (str, context.logger_data, info);
}

log_warning :: inline (
	fmt_str : string,
	args : ..Any,
	flags := Log_Flags.NONE,
	user_flags : u32 = 0,
	location := #caller_location
)
{
	log_message (fmt_str, ..args, remove_flag (flags, .ERROR) | .WARNING, user_flags, location);
}

// We often log an error then return false, so log_error returns false so you can
// have if statements with only one expression in the body, and no braces. i.e:
//
// if error_case
//     return log_error ("Error case true.");
//
// instead of:
//
// if error_case
// {
//     log_error ("Error case true.");
//     return false;
// }
log_error :: inline (
	fmt_str : string,
	args : ..Any,
	flags := Log_Flags.NONE,
	user_flags : u32 = 0,
	location := #caller_location
) -> bool
{
	log_message (fmt_str, ..args, remove_flag (flags, .WARNING) | .ERROR, user_flags, location);

	return false;
}
