AABB_Collider :: struct
{
	center : Vec3f;
	half_extents : Vec3f;
}

aabb_colliders : [..]AABB_Collider;

add_aabb_collider :: inline (collider : AABB_Collider)
{
	if !aabb_colliders.allocator.proc
		aabb_colliders.allocator = HEAP_ALLOC;
	push_into_array (*aabb_colliders, collider);
}

add_aabb_collider :: inline (center : Vec3f, half_extents : Vec3f)
{
	collider : AABB_Collider = ---;
	collider.center = center;
	collider.half_extents = half_extents;
	add_aabb_collider (collider);
}

draw_aabb_colliders :: inline (color : RGBA)
{
	for aabb_colliders
	{
		debug_draw_aabb (
			it.center,
			it.half_extents * 2,
			color
		);
	}
}

ray_intersects_aabb :: (
	ray_origin : Vec3f,
	ray_direction : Vec3f,
	aabb_center : Vec3f,
	aabb_half_extents : Vec3f
) ->
	intersects : bool #must,
	intersection_distance : f32,
	intersection_normal : Vec3f
{
	inv_dir := vec3f (1 / ray_direction.x, 1 / ray_direction.y, 1 / ray_direction.z);
	aabb_min := aabb_center - aabb_half_extents;
	aabb_max := aabb_center + aabb_half_extents;
	tx1 := (aabb_min.x - ray_origin.x) * inv_dir.x;
	tx2 := (aabb_max.x - ray_origin.x) * inv_dir.x;
	tmin := min (tx1, tx2);
	tmax := max (tx1, tx2);
	ty1 := (aabb_min.y - ray_origin.y) * inv_dir.y;
	ty2 := (aabb_max.y - ray_origin.y) * inv_dir.y;
	tmin = max (tmin, min (ty1, ty2));
	tmax = min (tmax, max (ty1, ty2));
	tz1 := (aabb_min.z - ray_origin.z) * inv_dir.z;
	tz2 := (aabb_max.z - ray_origin.z) * inv_dir.z;
	tmin = max (tmin, min (tz1, tz2));
	tmax = min (tmax, max (tz1, tz2));

	return tmax >= max (0.0, tmin), max (0.0, tmin), -ray_direction;
}

line_segment_intersects_aabb :: (
	line_origin : Vec3f,
	line_direction : Vec3f,
	line_length : f32,
	aabb_center : Vec3f,
	aabb_half_extents : Vec3f
) ->
	intersects : bool #must,
	intersection_distance : f32,
	intersection_normal : Vec3f
{
	intersects, distance, normal := inline ray_intersects_aabb (line_origin, line_direction, aabb_center, aabb_half_extents);

	return intersects && distance <= line_length, distance, normal;
}

line_cast :: inline (
	origin : Vec3f,
	direction : Vec3f,
	length : f32
) ->
	intersects : bool #must,
	intersection_distance : f32,
	intersection_normal : Vec3f
{
	intersects : bool;
	closest_distance := F32_POSITIVE_INFINITY;
	closest_normal : Vec3f;
	for aabb_colliders
	{
		ok, distance, normal := line_segment_intersects_aabb (
			origin, direction, length,
			it.center, it.half_extents
		);
		if ok
		{
			intersects = true;
			if distance < closest_distance
			{
				closest_distance = distance;
				closest_normal = normal;
			}
		}
	}

	return intersects, closest_distance, closest_normal;
}
