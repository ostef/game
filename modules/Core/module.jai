#if OS == .WINDOWS
	#import "Win32";

#load "assert.jai";
#load "alloc.jai";
#load "heap_alloc.jai";
#load "temp_alloc.jai";
#load "array.jai";
#load "logging.jai";
#load "string.jai";
#load "string_convert.jai";
#load "integer.jai";
#load "time.jai";

f32 :: float32;
f64 :: float64;

 S8_MIN ::                       -128;
 S8_MAX ::                        127;
 U8_MAX ::                        255;
S16_MIN ::                    -32_768;
S16_MAX ::                     32_767;
U16_MAX ::                     65_535;
S32_MIN ::             -2_147_483_648;
S32_MAX ::              2_147_483_647;
U32_MAX ::              4_294_967_295;
S64_MIN :: -9_223_372_036_854_775_808;
S64_MAX ::  9_223_372_036_854_775_807;
U64_MAX :: 18_446_744_073_709_551_615;

fill_default_context :: inline (ctx : *Context)
	#no_context
{
#if OS == .WINDOWS
	ctx.thread_index = GetCurrentThreadId ();
	ctx.allocator = HEAP_ALLOC;
}

fill_default_context :: inline ()
{
	fill_default_context (*context);
}

initialize_item :: inline (ptr : *$T)
{
	initializer :: initializer_of (T);
#if initializer
	initializer (ptr);
else
	memset (ptr, 0, size_of (T));
}

offset_of :: inline ($T : Type, $member : string) -> s64 #must
	#no_context
{
BODY :: #string END
dummy : T = ---;

return cast (*void) (*dummy.%) - cast (*void) *dummy;
END

	#insert #run fmt (context.allocator, BODY, member);
}

sign :: (val : $T) -> T #expand
{
	     if val < 0 then return -1;
	else if val > 0 then return  1;

	return 0;
}

abs :: (val : $T) -> T #expand
{
	if val < 0 then return -val;

	return val;
}

swap :: (a : *$T, b : *T) #expand
{
	temp := <<a;
	<<a = <<b;
	<<b = temp;
}

/*
min :: inline ($T : Type) -> T #must
#modify { if T.type != .INTEGER then T = null; }
{
#if T == u8
	return U8_MIN;
else #if T == s8
	return S8_MIN;
else #if T == u16
	return U16_MIN;
else #if T == s16
	return S16_MIN;
else #if T == u64
	return U64_MIN;
else #if T == s64
	return S64_MIN;
}

max :: inline ($T : Type) -> T #must
#modify { if T.type != .INTEGER then T = null; }
{
#if T == u8
	return U8_MAX;
else #if T == s8
	return S8_MAX;
else #if T == u16
	return U16_MAX;
else #if T == s16
	return S16_MAX;
else #if T == u64
	return U64_MAX;
else #if T == s64
	return S64_MAX;
}
*/

min :: (a : $T, b : T) -> T #expand
{
	return ifx a < b then a else b;
}

max :: (a : $T, b : T) -> T #expand
{
	return ifx a > b then a else b;
}

min :: (first : $T, args : ..T) -> T #expand
{
	result := first;
	for args
	{
		if it < result then result = it;
	}

	return result;
}

max :: (first : $T, args : ..T) -> T #expand
{
	result := first;
	for args
	{
		if it > result then result = it;
	}

	return result;
}

clamp :: (x : $T, min : T, max : T) -> T #expand
{
	if x > max then x = max;
	if x < min then x = min;

	return x;
}

saturate :: clamp01;
clamp01 :: (x : $T) -> T #expand
{
	return clamp (x, 0, 1);
}

flagged :: (val : $T, flag : T) -> bool #expand
{
	return (val & flag) == flag;
}

add_flag :: (val : $T, flag : T) -> T #expand
{
	return val | flag;
}

add_flag :: (val : *$T, flag : T) #expand
{
	<<val |= flag;
}

remove_flag :: (val : $T, flag : T) -> T #expand
{
	return val & ~flag;
}

remove_flag :: (val : *$T, flag : T) #expand
{
	<<val &= ~flag;
}

