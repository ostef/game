// @Todo (stefan): Find a way to identify the module that logged the message.
// Maybe use the location, or we can have log_message be a macro, that looks
// up a variable called MODULE_NAME for example. But then, we won't be able
// to use external modules as-is. Can we check if an identifier is declared ?
// Can we insert that identifier for every module at module scope using a metaprogram ?

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
	str := fmt (TEMP_ALLOC, fmt_str, ..args);
	if str.count == 0
		return;
	info : Log_Info;
	//info.source_identifier = `MODULE_NAME_HASH;
	info.location = location;
	info.common_flags = remove_flag (flags, Log_Flags.ERROR | .WARNING);
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
