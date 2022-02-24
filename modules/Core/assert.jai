#import "Fmt";
#import "String_Builder";

ENABLE_ASSERTS :: true;

always_panic :: inline (fmt_str := "", args : ..Any, location := #caller_location)
{
	// Prevent assert ()->...->assert ()->...->assert ()->...->assert () infinite recursion
	if !context.handling_assertion_failure
	{
		temporary_block ();
		str := fmt (TEMP_ALLOC, fmt_str, ..args);
		context.handling_assertion_failure = true;
		context.assertion_failed (location, str);
		context.handling_assertion_failure = false;
	}
}

always_assert :: inline (assertion : bool, fmt_str := "", args : ..Any, location := #caller_location)
{
	// Prevent assert ()->...->assert ()->...->assert ()->...->assert () infinite recursion
	if !assertion && !context.handling_assertion_failure
	{
		temporary_block ();
		str := fmt (TEMP_ALLOC, fmt_str, ..args);
		context.handling_assertion_failure = true;
		context.assertion_failed (location, str);
		context.handling_assertion_failure = false;
	}
}

panic :: (fmt_str := "", args : ..Any, location := #caller_location) #expand
{
#if ENABLE_ASSERTS
	always_panic (fmt_str, ..args, location);
}

// @Note (stefan): We take a Code instead of a bool so we choose whether or not the expression gets
// evaluated ourselves. The expression we want to assert might take a long time to execute, so we
// need to be able to not evaluate the expression when assertions are disabled, otherwise we won't get
// much of a performance boost in release builds.
assert :: (assertion_expr : Code, fmt_str := "", args : ..Any, location := #caller_location) #expand
{
#if ENABLE_ASSERTS
	always_assert (#insert assertion_expr, fmt_str, ..args, location);
}
