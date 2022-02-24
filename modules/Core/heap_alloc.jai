HEAP_ALLOC :: Allocator.{ heap_allocator_proc, null };

heap_allocator_proc :: (mode : Allocator_Mode, size : s64, old_size : s64, old_ptr : *void, allocator_data : *void) -> *void
{
	if #complete mode ==
	{
	case .ALLOCATE;
		return platform_heap_alloc (size);
	case .RESIZE;
		return platform_heap_realloc (old_ptr, size);
	case .FREE;
		platform_heap_free (old_ptr);
	}
	return null;
}

#scope_file

#if OS == .WINDOWS
{

#import "Win32";

// @Note (stefan): Memory allocated with heap functions is MEMORY_ALLOCATION_ALIGNMENT
// bytes aligned, which is defined to be 16 bytes in Win32/kernel32.jai.

platform_heap_alloc :: inline (size : s64) -> *void #must
{
	heap := GetProcessHeap ();
	assert (heap != null, "GetProcessHeap returned null: %", win32_get_last_error ());

	return HeapAlloc (heap, 0, xx size);
}

platform_heap_realloc :: inline (ptr : *void, new_size : s64) -> *void #must
{
	heap := GetProcessHeap ();
	assert (heap != null, "GetProcessHeap returned null: %", win32_get_last_error ());

	return HeapReAlloc (heap, 0, ptr, xx new_size);
}

platform_heap_free :: inline (ptr : *void)
{
	heap := GetProcessHeap ();
	assert (heap != null, "GetProcessHeap returned null: %", win32_get_last_error ());
	HeapFree (heap, 0, xx ptr);
}

}
