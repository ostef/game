approx_zero :: inline (val : f32, epsilon := F32_EPSILON) -> bool #must
	#no_context
{
	return abs (val) <= epsilon;
}

approx_zero :: inline (val : f64, epsilon := F64_EPSILON) -> bool #must
	#no_context
{
	return abs (val) <= epsilon;
}

approx_equals :: inline (left : f32, right : f32, epsilon := F32_EPSILON) -> bool #must
	#no_context
{
	return abs (left - right) <= epsilon;
}

approx_equals :: inline (left : f64, right : f64, epsilon := F64_EPSILON) -> bool #must
	#no_context
{
	return abs (left - right) <= epsilon;
}
