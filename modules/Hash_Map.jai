#import "Core";
#import "Hash";

Hash_Map :: struct (
	TKey : Type,
	TVal : Type,
	hash_func : (TKey) -> u32 = null,
	comp_func : (TKey, TKey) -> bool = null,
	EXPAND_LIMIT := 70
)
{
	Entry :: struct
	{
		hash  : u32;
		key   : TKey;
		value : TVal;
	}

	count     : s64;
	allocated : s64;
	occupied  : s64;
	entries   : []Entry;
	allocator : Allocator;

#if hash_func
	hash_key :: hash_func;
else
	hash_key :: (key) => default_hash (key);

#if comp_func
	compare_keys :: comp_func;
else
	compare_keys :: (left, right) => left == right;

	MIN_CAPACITY        :: 32;
	NEVER_OCCUPIED_HASH :: 0;
	REMOVED_HASH        :: 1;
	FIRST_OCCUPIED_HASH :: 2;
}

for_expansion :: (map : *$T/Hash_Map, body : Code, flags : For_Flags) #expand
{
	for * entry, i : map.entries
	{
		if entry.hash < map.FIRST_OCCUPIED_HASH then continue;

		`it_index := entry.key;
#if flags & .POINTER
		`it := *entry.value;
else
		`it := entry.value;
		#insert (remove = { entry.hash = REMOVED_HASH; map.count -= 1; }) body;
	}
}

init_map :: inline (map : *Hash_Map, capacity : s64, allocator : Allocator)
{
	capacity = next_power_of_two (capacity);
	capacity = min (capacity, map.MIN_CAPACITY);

	map.count = 0;
	map.occupied = 0;
	map.allocated = capacity;
	map.allocator = allocator;
	map.entries = alloc_array (map.Entry, capacity, allocator);
	for * map.entries
		it.hash = map.NEVER_OCCUPIED_HASH;
}

reset_map :: inline (using map : *Hash_Map)
{
	free (entries.data, allocator);
	entries.data = null;
	entries.count = 0;
	count = 0;
	occupied = 0;
	allocated = 0;
}

clear_map :: inline (using map : *Hash_Map)
{
	count = 0;
	occupied = 0;
	for * entries
		it.hash = NEVER_OCCUPIED_HASH;
}

grow_map :: inline (map : *Hash_Map)
{
	old_entries := map.entries;
	new_capacity := map.allocated * 2;
	new_capacity = max (new_capacity, map.MIN_CAPACITY);

	map.entries = alloc_array (map.Entry, new_capacity, map.allocator);
	map.count = 0;
	map.occupied = 0;
	map.allocated = new_capacity;
	for entry, i : old_entries
	{
		if entry.hash >= map.FIRST_OCCUPIED_HASH
			insert_into_map (map, entry.key, entry.value);
	}
	free (old_entries.data, map.allocator);
}

insert_into_map :: (map : *Hash_Map, key : map.TKey, $initialize := true) -> *map.TVal #must, was_present : bool
{
	if (map.occupied + 1) * 100 >= map.allocated * map.EXPAND_LIMIT
		grow_map (map);
	assert (map.occupied <= map.allocated);

	hash := map.hash_key (key);
	if hash < map.FIRST_OCCUPIED_HASH then hash += map.FIRST_OCCUPIED_HASH;
	index := hash & (map.allocated - 1);

	// Check if the key-value pair is already in the map
	while map.entries[index].hash
	{
		entry := *map.entries[index];
		if entry.hash == hash && map.compare_keys (entry.key, key)
			return *entry.value, true;
		index += 1;
		if index >= map.allocated then index = 0;
	}

	map.occupied += 1;
	map.count    += 1;

	entry := *map.entries[index];
	entry.hash = hash;
	entry.key  = key;
#if initialize then initialize_item (*entry.value);

	return *entry.value, false;
}

insert_into_map :: inline (map : *Hash_Map, key : map.TKey, value : map.TVal) -> *map.TVal, was_present : bool
{
	ptr, was_present := insert_into_map (map, key);
	<<ptr = value;
	
	return ptr, was_present;
}

remove_from_map :: (map : *Hash_Map, key : map.TKey) -> found : bool
{
	hash := map.hash_key (key);
	if hash < map.FIRST_OCCUPIED_HASH then hash += map.FIRST_OCCUPIED_HASH;
	
	index := hash & (map.allocated - 1);
	while map.entries[index].hash
	{
		entry := *map.entries[index];
		
		if entry.hash == hash && map.compare_keys (entry.key, key)
		{
			entry.hash = map.REMOVED_HASH;
			map.count -= 1;
			
			return true;
		}
		
		index += 1;
		if index >= map.allocated then index = 0;
	}
	
	return false;
}

set_value :: inline (map : *Hash_Map, key : map.TKey, value : map.TVal)
{
	ptr := get_pointer (map, key);
	if ptr then <<ptr = value;
}

get_pointer :: (map : Hash_Map, key : map.TKey) -> *map.TVal #must
{
	if map.count == 0 then return null;
	
	hash := map.hash_key (key);
	if hash < map.FIRST_OCCUPIED_HASH then hash += map.FIRST_OCCUPIED_HASH;
	index := hash & (map.allocated - 1);
	
	while map.entries[index].hash
	{
		entry := *map.entries[index];
		if entry.hash == hash && map.compare_keys (entry.key, key)
			return *entry.value;
		index += 1;
		if index >= map.allocated then index = 0;
	}
	
	return null;
}

get_value :: (map : Hash_Map, key : map.TKey, fallback : map.TVal) -> map.TVal #must, found : bool
{
	ptr := inline get_pointer (map, key);
	if ptr then return <<ptr, true;

	return fallback, false;
}

next_power_of_two :: inline (x : s64) -> s64 #must
{
	assert (x > 0, "Invalid x (got %, expected x > 0).", x);
	p := 1;
	while x > p
		p += p;
	
	return p;
}
