#import "Core";

Storage :: struct (T : Type, items_per_page : s32)
{
	Slot :: struct
	{
		prev     : *~s32 Slot;
		next     : *~s32 Slot;
		occupied : bool;
		version  : u32;
	}

	Page :: struct
	{
		prev  : *~s32 Page;
		next  : *~s32 Page;
		index : u32;
		count : s32;
		items : [items_per_page]T = ---;
		slots : [items_per_page]Slot;
		free_slots     : *Slot;
		occupied_slots : *Slot;
	}

	count : s64;
	all_pages  : [..]*Page;
	free_pages : *Page;
	full_pages : *Page;
	allocator : Allocator;
}

Slot_Info :: struct
{
	version     : u32;
	is_new_page : bool;
	page_index  : s64;
	slot_index  : s64;
}

init_storage :: inline (storage : *Storage, allocator : Allocator)
{
	storage.count = 0;
	storage.free_pages = null;
	storage.full_pages = null;
	storage.allocator  = allocator;
	init_array (*storage.all_pages, 10, allocator);
}

reset_storage :: inline (using storage : *Storage)
{
	while free_pages
	{
		next = free_pages.next;
		free (free_pages, allocator);
		free_pages = next;
	}
	while full_pages
	{
		next = full_pages.next;
		free (full_pages, allocator);
		full_pages = next;
	}
	count = 0;
}

find_free_slot :: (using storage : *Storage, $initialize := true) -> *storage.T #must, info : Slot_Info
{
	info : Slot_Info;
	page := free_pages;
	if !page
	{
		info.is_new_page = true;
		page = new (Page, allocator);
		for i : 0..items_per_page - 2
			page.slots[i].next = *page.slots[i + 1];
		page.free_slots = *page.slots[0];
		free_pages = page;
		push_into_array (*all_pages, page);
		page.index = cast (u32) (all_pages.count - 1);
	}
	slot := page.free_slots;
	assert (page.count < items_per_page, "Page is full even though it is in the free pages list.");
	assert (slot != null, "Could not find free slot even though the page is in the free pages list.");
	// Add the slot to the occupied slots list
	page.free_slots = slot.next;
	slot.next = page.occupied_slots;
	if slot.next
		slot.next.prev = slot;
	page.occupied_slots = slot;
	slot.occupied = true;
	// If there are no more free slots, add the page to the full pages list
	if !page.free_slots
	{
		free_pages = page.next;
		page.next = full_pages;
		if page.next
			page.next.prev = page;
		full_pages = page;
	}
	slot.version += 1;
	item := *page.items[info.slot_index];
#if initialize
	initialize_item (item);
	page.count += 1;
	count += 1;
	info.version = slot.version;
	info.page_index = page.index;
	info.slot_index = cast (s64) (slot - page.slots.data) / size_of (Slot);

	return item, info;
}

release_slot :: (using storage : *Storage, info : Slot_Info)
{
	page := all_pages[info.page_index];
	page_was_full := page.free_slots == null;
	assert (page.slots[info.slot_index].occupied, "Releasing unnocupied slot % in page %.", info.slot_index, info.page_index);
	slot := *page.slots[info.slot_index];
	slot.occupied = false;
	// Remove the slot from the occupied slots list
	if page.occupied_slots == slot
		page.occupied_slots = slot.next;
	if slot.prev
		slot.prev.next = slot.next;
	if slot.next
		slot.next.prev = slot.prev;
	// Add the slot to the free slots list
	slot.prev = null;
	slot.next = page.free_slots;
	page.free_slots = slot;
	page.count -= 1;
	// Add the page to the free pages list if it was full previously
	if page_was_full
	{
		if full_pages == page
			full_pages = page.next;
		if page.prev
			page.prev.next = page.next;
		if page.next
			page.next.prev = page.prev;
		page.prev = null;
		page.next = free_pages;
		free_pages = page;
	}
	count -= 1;
}

release_slot :: inline (using storage : *Storage, item : *storage.T) -> bool
{
	valid, info, occupied := get_slot_info (storage, item);
	if !valid || !occupied
		return false;
	release_slot (storage, info);

	return true;
}

release_all :: (using storage : *Storage)
{
	if count == 0 || pages.count == 0
		return;
	for page, i : pages
	{
		for * slot, si : slots
		{
			slot.occupied = false;
			if si != 0
				slot.prev = *page.slots[si - 1];
			else
				slot.prev = null;
			if si != items_per_page - 1
				slot.next = *page.slots[si + 1];
			else
				slot.next = null;
		}
		page.free_slots = *pages.slots[0];
		page.occupied_slots = null;
		if i != 0
			page.prev = pages[i - 1];
		else
			page.prev = null;
		if i != pages.count - 1
			page.next = pages[i + 1];
		else
			page.next = null;
	}
	free_pages = pages[0];
	full_pages = null;
}

reset_storage :: inline (using storage : *Storage)
{
	for page : pages
		free (page, allocator);
	reset_array (*pages, allocator);
	count = 0;
	free_pages = null;
	full_pages = null;
}

get_slot_info :: (using storage : *Storage, item : *storage.T) -> valid : bool, info : Slot_Info, occupied : bool
{
	info : Slot_Info;
	for page : all_pages
	{
		first_item := *page.items[0];
		last_item  := *page.items[items_per_page - 1];
		if item >= first_item && item <= last_item
		{
			slot_index := cast (s64) (item - first_item) / size_of (T);
			info.version = page.slots[slot_index].version;
			info.page_index = page.index;
			info.slot_index = slot_index;

			return true, info, page.slots[slot_index].occupied;
		}
	}

	return false, info, false;
}
