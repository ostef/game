clone_array :: inline (array : []$T, allocator : Allocator) -> []T #must
{
	result : []T = ---;
	result.data = alloc (size_of (T) * array.count, allocator);
	memcpy (result.data, array.data, size_of (T) * array.count);
	result.count = array.count;

	return result;
}

init_array :: inline (array : *[..]$T, capacity : s64, allocator : Allocator)
{
	assert (capacity >= 0);
	array.data = alloc (size_of (T) * capacity, allocator);
	array.count = 0;
	array.allocated = capacity;
	array.allocator = allocator;
}

clear_array :: inline (array : *[..]$T)
{
	array.count = 0;
}

reset_array :: inline (array : *[..]$T)
{
	free (array.data, array.allocator);
	array.data = null;
	array.count = 0;
	array.allocated = 0;
}

grow_array :: inline (array : *[..]$T, additional_elements : s64)
{
	assert (array.allocator.proc != null, "Array is not initialized.");
	if additional_elements <= 0
		return;
	new_capacity := array.allocated + additional_elements;
	new_data := realloc (array.data, size_of (T) * array.allocated, size_of (T) * new_capacity, array.allocator);
	array.data = new_data;
	array.allocated = new_capacity;
}

push_into_array :: inline (array : *[..]$T, $initialize := true) -> *T #must
{
	if array.count == array.allocated
		grow_array (array, array.allocated + 8);
	ptr := *array.data[array.count];
#if initialize then initialize_item (ptr);
	array.count += 1;

	return ptr;
}

push_into_array :: inline (array : *[..]$T, item : T) -> *T
{
	ptr := push_into_array (array, initialize = false);
	<<ptr = item;

	return ptr;
}

pop_off_array :: inline (array : *[..]$T) -> T
{
	assert (array.count > 0, "Array is empty.");
	array.count -= 1;

	return array.data[array.count];
}

insert_into_array :: inline (array : *[..]$T, position : s64, $initialize := true) -> *T #must
{
	assert (position >= 0 && position <= array.count, "Index % out of range [0, %).", position, array.count);

	if array.count == array.allocated
		grow_array (array, array.allocated + 8);
	if position < array.count
		push_into_array (array, array[position]);
#if initialize then initialize_item (*array.data[position]);

	return *array.data[position];
}

insert_into_array :: inline (array : *[..]$T, position : s64, item : T) -> *T
{
	ptr := insert_into_array (array, position, initialize = false);
	<<ptr = item;

	return ptr;
}

sorted_insert_into_array :: inline (array : *[..]$T, position : s64, $initialize := false) -> *T #must
{
	assert (position >= 0 && position <= array.count, "Index % out of range [0, %).", position, array.count);

	if array.count == array.allocated
		grow_array (array, array.count + 8);
	array.count += 1;
	for < i : array.count - 1..position + 1
		array.data[i] = array.data[i - 1];
	ptr := *array.data[position];
#if initialize then initialize_item (ptr);

	return ptr;
}

sorted_insert_into_array :: inline (array : *[..]$T, position : s64, elem : T) -> *T
{
	ptr := sorted_insert_into_array (array, position);
	<<ptr = elem;

	return ptr;
}

remove_from_array :: inline (array : *[..]$T, position : s64) -> T
{
	assert (position >= 0 && position <= array.count, "Index % out of range [0, %).", position, array.count);

	result := array.data[position];
	array.data[position] = array.data[array.count - 1];
	array.count -= 1;

	return result;
}

sorted_remove_from_array :: inline (array : *[..]$T, position : s64)
{
	assert (position >= 0 && position < array.count, "Index % out of range [0, %).", position, array.count);

	for i : position..array.count - 2
		array.data[i] = array.data[i + 1];
	array.count -= 1;
}

find_first_occurence :: inline (array : []$T, val : T) -> s64 #must
{
	for array
	{
		if it == val
			return it_index;
	}

	return -1;
}

find_last_occurence :: inline (array : []$T, val : T) -> s64 #must
{
	for < array
	{
		if it == val
			return it_index;
	}

	return -1;
}

advance :: inline (array : []$T, count := 1) -> []T #must
{
	count = clamp (count, 0, array.count);
	result : []T = ---;
	result.data  = array.data + count;
	result.count = array.count - count;

	return result;
}
