TRAP_ALLOC :: Allocator.{ trap_allocator_proc, null };

trap_allocator_proc :: (mode : Allocator_Mode, size : s64, old_size : s64, old_ptr : *void, allocator_data : *void) -> *void
{
	panic ("Called trap allocator.");
	return null;
}

alloc :: inline (size : s64, allocator : Allocator) -> *void #must
{
	if size <= 0
		return null;
	return allocator.proc (.ALLOCATE, size, 0, null, allocator.data);
}

realloc :: inline (ptr : *void, old_size : s64, new_size : s64, allocator : Allocator) -> *void #must
{
	if new_size <= 0
	{
		free (ptr, allocator);

		return null;
	}
	if !ptr
		return alloc (new_size, allocator);

	return allocator.proc (.RESIZE, new_size, old_size, ptr, allocator.data);
}

new :: inline ($T : Type, allocator : Allocator) -> *T #must
{
	result := cast (*T) alloc (size_of (T), allocator);
	if !result
		return null;
	initialize_item (result);

	return result;
}

alloc_array :: inline ($T : Type, count : s64, allocator : Allocator, $initialize := false) -> []T #must
{
	result : []T = ---;
	result.data = cast (*T) alloc (size_of (T) * count, allocator);
	if !result.data
		return .[];
	result.count = count;
#if initialize
{
	initializer :: initializer_of (T);
#if initializer
{
	for i : 0..count - 1 #no_abc
	{
		initializer (*result[i]);
	}
}
else
	memset (result.data, 0, size_of (T) * count);
}

	return result;
}

free :: inline (ptr : *void, allocator : Allocator)
{
	if ptr
		allocator.proc (.FREE, 0, 0, ptr, allocator.data);
}

free :: inline (str : string, allocator : Allocator)
{
	free (str.data, allocator);
}

free :: inline (array : []$T, allocator : Allocator)
{
	free (array.data, allocator);
}
