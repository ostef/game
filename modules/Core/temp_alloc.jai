#import "Memory";

TEMP_ALLOC :: Allocator.{ temporary_allocator_proc, null };

temporary_allocator_proc :: (mode : Allocator_Mode, size : s64, old_size : s64, old_ptr : *void, allocator_data : *void) -> *void
{
	storage : *Temporary_Storage = ---;
	if allocator_data
		storage = cast (*Temporary_Storage) allocator_data;
	else
		storage = context.temporary_storage;
	return inline arena_allocator_proc (mode, size, old_size, old_ptr, storage);
}

reset_temporary_storage :: inline (storage := context.temporary_storage)
{
	reset_memory_arena (storage);
}

Temporary_Storage_State :: Memory_Arena_State;

get_temporary_storage_state :: inline (storage := context.temporary_storage) -> Temporary_Storage_State
{
	return get_memory_arena_state (storage);
}

set_temporary_storage_state :: inline (state : Temporary_Storage_State, storage := context.temporary_storage)
{
	set_memory_arena_state (state, storage);
}

temporary_block :: (storage := context.temporary_storage) #expand
{
	state := get_temporary_storage_state (storage);
	`defer set_temporary_storage_state (state, storage);
}
