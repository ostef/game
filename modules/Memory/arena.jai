// A memory arena allocator follows the pattern of bulk deallocations, very much like
// the temporary allocator (the temporary storage is actually a memory arena, which is
// why we make Memory_Arena an alias for Temporary_Storage). See the how_to about the
// temporary storage for why this allocation pattern is very useful and can be a substitute
// for traditional garbage collection. Though I would consider this a garbage collection
// mecanism, that `assumes` the memory is not used anymore instead of making sure it
// is not used anymore through expensive design and algorithms. Also it is less expensive
// than heap allocations, so using the temporary storage is not even a tradeoff thing,
// it's just not usable for all cases.

Memory_Arena :: Temporary_Storage;

// By default, disable overflow by giving overflow_allocator a default value of { null, null } 
init_arena :: inline (arena : *Memory_Arena, size : s64, allocator : Allocator, overflow_allocator := Allocator.{ null, null })
{
	initialize_item (arena);
	arena.data = alloc (size, allocator);
	if !arena.data then return;
	arena.size = size;
	arena.overflow_allocator = overflow_allocator;
	arena.original_data = arena.data;
	arena.original_size = size;
}

arena_allocator :: inline (arena : *Memory_Arena) -> Allocator #must
{
	result : Allocator = ---;
	result.proc = arena_allocator_proc;
	result.data = arena;

	return result;
}

arena_allocator_proc :: (mode : Allocator_Mode, size : s64, old_size : s64, old_ptr : *void, allocator_data : *void) -> *void
{
	ALIGNMENT :: 8;

	arena := cast (*Memory_Arena) allocator_data;
	assert (arena != null, "Memory arena is null.");
	if #complete mode ==
	{
	case .FREE;
		return null;

	case .RESIZE; #through;
	case .ALLOCATE;
		aligned_size := (size + ALIGNMENT - 1) & ~(ALIGNMENT - 1);
		if arena.occupied + aligned_size > arena.size
		{
			log_message ("Allocating new page for arena %.", arena);
			if !add_page (arena, aligned_size)
			{
				log_error ("Could not allocate new page for arena %.", arena);

				return null;
			}
		}
		result := arena.data + arena.occupied;
		arena.occupied += xx aligned_size;
		arena.high_water_mark = max (arena.high_water_mark, arena.occupied);
		if mode == .RESIZE
			memcpy (result, old_ptr, min (old_size, size));

		return result;
	}

	return null;
}

reset_memory_arena :: inline (arena : *Memory_Arena)
{
	if !arena then return;
	arena.data = arena.original_data;
	arena.size = arena.original_size;
	arena.occupied = 0;
	arena.high_water_mark = 0;
	free_pages (arena);
}

Memory_Arena_State :: struct
{
	page : *Memory_Arena.Overflow_Page;
	occupied : s64;
}

get_memory_arena_state :: inline (arena : *Memory_Arena) -> Memory_Arena_State #must
{
	if !arena then return .{};
	state : Memory_Arena_State = ---;
	state.occupied = arena.occupied;
	state.page = arena.overflow_pages;

	return state;
}

set_memory_arena_state :: inline (state : Memory_Arena_State, arena : *Memory_Arena)
{
	if !arena then return;
	free_pages (arena, state.page);

	if state.page
	{
		arena.data = cast (*u8) state.page + ALIGNED_OVERFLOW_PAGE_ALLOCATION;
		arena.size = state.page.size;
	}
	else
	{
		arena.data = arena.original_data;
		arena.size = arena.original_size;
	}
	arena.occupied = state.occupied;
}

#scope_file

ALIGNED_OVERFLOW_PAGE_ALLOCATION :: 32;

add_page :: inline (arena : *Memory_Arena, min_size : s64) -> bool
{
	data_size := arena.original_size - ALIGNED_OVERFLOW_PAGE_ALLOCATION;
	data_size = max (data_size, min_size);
	total_size := data_size + ALIGNED_OVERFLOW_PAGE_ALLOCATION;
	assert (arena.overflow_allocator.proc != null, "Overflow allocator was null.");
	mem := alloc (total_size, arena.overflow_allocator);
	if !mem then return false;

	page := cast (*Memory_Arena.Overflow_Page) mem;
	page.next = arena.overflow_pages;
	page.allocator = arena.overflow_allocator;
	page.size = data_size;

	arena.overflow_pages = page;
	arena.data = mem + ALIGNED_OVERFLOW_PAGE_ALLOCATION;
	arena.size = data_size;
	arena.occupied = 0;
	
	return true;
}

free_pages :: inline (arena : *Memory_Arena, page : *Memory_Arena.Overflow_Page = null)
{
	current := arena.overflow_pages;
	while current && current != page
	{
		next := current.next;
		free (current, current.allocator);
		current = next;
	}
	arena.overflow_pages = current;
}
