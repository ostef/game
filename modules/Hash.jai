FNV_OFFSET_BASIS_32 : u32 : 0x811c_9dc5;
FNV_PRIME_32        : u32 : 0x0100_0193;

FNV_OFFSET_BASIS_64 : u64 : 0xcbf2_9ce4_8422_2325;
FNV_PRIME_64        : u64 : 0x0000_0100_0000_01b3;

fnv1_hash :: inline (data : *void, count : s64) -> u32 #must
{
	hash := FNV_OFFSET_BASIS_32;

	for i : 0..count - 1 #no_abc
	{
		hash *= FNV_PRIME_32;
		hash ^= (cast (*u8) data)[i];
	}

	return hash;
}

fnv1a_hash :: inline (data : *void, count : s64) -> u32 #must
{
	hash := FNV_OFFSET_BASIS_32;

	for i : 0..count - 1 #no_abc
	{
		hash ^= (cast (*u8) data)[i];
		hash *= FNV_PRIME_32;
	}

	return hash;
}

fnv1_hash64 :: inline (data : *void, count : s64) -> u64 #must
{
	hash := FNV_OFFSET_BASIS_64;

	for i : 0..count - 1 #no_abc
	{
		hash *= FNV_PRIME_64;
		hash ^= (cast (*u8) data)[i];
	}

	return hash;
}

fnv1a_hash64 :: inline (data : *void, count : s64) -> u64 #must
{
	hash := FNV_OFFSET_BASIS_64;

	for i : 0..count - 1 #no_abc
	{
		hash ^= (cast (*u8) data)[i];
		hash *= FNV_PRIME_64;
	}

	return hash;
}

/* http://www.cse.yorku.ca/~oz/hash.html:
 *
 * "This algorithm (k=33) was first reported by dan bernstein many years ago in comp.lang.c. another version of this algorithm
 * (now favored by bernstein) uses xor:
 * 
 * hash(i) = hash(i - 1) * 33 ^ str[i];
 * 
 * the magic of number 33 (why it works better than many other constants, prime or not) has never been adequately explained.
 */
DJB2_DEFAULT_BASIS :: 5_381;
djb2_hash :: inline (data : *void, count : s64, h : u32 = DJB2_DEFAULT_BASIS) -> u32 #must
{
	for i : 0..count - 1 #no_abc
	{
		//h = (h << 5) + hash + (cast (*u8) data)[i];
		h = h * 33 ^ (cast (*u8) data)[i];
	}

	return h;
}

/* http://www.cse.yorku.ca/~oz/hash.html:
 *
 * "This algorithm was created for sdbm (a public-domain reimplementation of ndbm) database library. it was found to do well in
 * scrambling bits, causing better distribution of the keys and fewer splits. it also happens to be a good general hashing function
 * with good distribution. the actual function is
 *
 * hash(i) = hash(i - 1) * 65599 + str[i];
 *
 * what is included below is the faster version used in gawk. [there is even a faster, duff-device version] the magic constant 65599
 * was picked out of thin air while experimenting with different constants, and turns out to be a prime. this is one of the algorithms
 * used in berkeley db (see sleepycat) and elsewhere."
 */
SDBM_DEFAULT_BASIS :: 5_381;
sdbm_hash :: inline (data : *void, count : s64, h : u32 = SDBM_DEFAULT_BASIS) -> u32 #must
{
	for i : 0..count - 1 #no_abc
	{
		h = (h << 16) + (h << 6) - h + (cast (*u8) data)[i];
	}

	return h;
}

default_hash :: inline (str : string) -> u32 #must
{
	return fnv1a_hash (str.data, str.count);
}

default_hash64 :: inline (str : string) -> u64 #must
{
	return fnv1a_hash64 (str.data, str.count);
}

default_hash :: inline (val : $T) -> u32 #must
{
	return sdbm_hash (*val, size_of (T));
}
