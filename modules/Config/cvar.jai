CVar :: struct
{
	Value :: struct
	{
		Kind :: enum
		{
			UNKNOWN :: 0;
			BOOL  :: 1;
			S64   :: 2;
			U64   :: 3;
			F32   :: 4;
			F64   :: 5;
			STRING :: 6;
		}

		kind : Kind;
		union
		{
			as_bool   : bool;
			as_s64    : s64;
			as_u64    : u64;
			as_f32    : f32;
			as_f64    : f64;
			as_string : string;
		};
	}

	On_Value_Changed_Callback :: #type (previous_value : Value, value : Value, last_set : Source_Code_Location, location : Source_Code_Location);

	using value : Value;
	name : string;
	description : string;
	last_set : Source_Code_Location;
	on_value_changed : On_Value_Changed_Callback;	// @Note (stefan): Should this be an array of callbacks ?
}

#scope_file

registered_cvars : Hash_Map (string, CVar);

#scope_export

init_cvars :: inline ()
{
	init_map (*registered_cvars, 100, HEAP_ALLOC);
}

register_cvar :: inline (name : string, description : string, kind : CVar.Value.Kind, location := #caller_location) -> bool
{
	cvar, present := insert_into_map (*registered_cvars, name);
	if present
		return false;
	cvar.kind = kind;
	cvar.name = name;
	cvar.description = description;
	cvar.last_set = location;

	return true;
}

unregister_cvar :: inline (name : string) -> bool
{
	return remove_from_map (*registered_cvars, name);
}

set_cvar_callback :: inline (name : string, callback : CVar.On_Value_Changed_Callback) -> bool
{
	cvar := get_pointer (*registered_cvars, name);
	if !cvar then return false;
	cvar.on_value_changed = callback;

	return true;
}

get_cvar_last_set_location :: inline (name : string) -> Source_Code_Location #must, bool
{
	cvar := get_pointer (*registered_cvars, name);
	if !cvar then return .{}, false;

	return cvar.last_set, true;
}

get_cvar :: inline (name : string) -> CVar.Value #must
{
	cvar := get_pointer (*registered_cvars, name);
	if !cvar then return .{};

	return cvar.value;
}

get_bool_cvar :: inline (name : string) -> bool #must, bool
{
	var := get_cvar (name);
	if var.kind != .BOOL then return false, false;

	return var.as_bool, true;
}

get_s64_cvar :: inline (name : string) -> s64 #must, bool
{
	var := get_cvar (name);
	if var.kind != .S64 then return 0, false;

	return var.as_s64, true;
}

get_u64_cvar :: inline (name : string) -> u64 #must, bool
{
	var := get_cvar (name);
	if var.kind != .U64 then return 0, false;

	return var.as_u64, true;
}

get_f32_cvar :: inline (name : string) -> f32 #must, bool
{
	var := get_cvar (name);
	if var.kind != .F32 then return 0, false;

	return var.as_f32, true;
}

get_f64_cvar :: inline (name : string) -> f64 #must, bool
{
	var := get_cvar (name);
	if var.kind != .F64 then return 0, false;

	return var.as_f64, true;
}

get_string_cvar :: inline (name : string) -> string #must, bool
{
	var := get_cvar (name);
	if var.kind != .STRING then return "", false;

	return var.as_string, true;
}

set_cvar :: inline (name : string, val : CVar.Value, location := #caller_location) -> bool
{
	cvar := get_pointer (*registered_cvars, name);
	if !cvar || cvar.kind != val.kind
		return false;
	previous_value := cvar.value;
	last_set := cvar.last_set;
	cvar.value = val;
	cvar.last_set = location;
	if cvar.on_value_changed
		cvar.on_value_changed (previous_value, cvar.value, last_set, location);

	return true;
}

set_bool_cvar :: inline (name : string, val : bool, location := #caller_location) -> bool
{
	cvar_val : CVar.Value = ---;
	cvar_val.kind = .BOOL;
	cvar_val.as_bool = val;

	return set_cvar (name, cvar_val, location);
}

set_s64_cvar :: inline (name : string, val : s64, location := #caller_location) -> bool
{
	cvar_val : CVar.Value = ---;
	cvar_val.kind = .S64;
	cvar_val.as_s64 = val;

	return set_cvar (name, cvar_val, location);
}

set_u64_cvar :: inline (name : string, val : u64, location := #caller_location) -> bool
{
	cvar_val : CVar.Value = ---;
	cvar_val.kind = .U64;
	cvar_val.as_u64 = val;

	return set_cvar (name, cvar_val, location);
}

set_f32_cvar :: inline (name : string, val : f32, location := #caller_location) -> bool
{
	cvar_val : CVar.Value = ---;
	cvar_val.kind = .F32;
	cvar_val.as_f32 = val;

	return set_cvar (name, cvar_val, location);
}

set_f64_cvar :: inline (name : string, val : f64, location := #caller_location) -> bool
{
	cvar_val : CVar.Value = ---;
	cvar_val.kind = .F64;
	cvar_val.as_f64 = val;

	return set_cvar (name, cvar_val, location);
}

set_string_cvar :: inline (name : string, val : string, location := #caller_location) -> bool
{
	cvar_val : CVar.Value = ---;
	cvar_val.kind = .STRING;
	cvar_val.as_string = val;

	return set_cvar (name, cvar_val, location);
}
