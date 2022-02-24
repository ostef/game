Skeleton :: struct
{
	Joint :: struct
	{
		name     : string;
		id       : s16;
		parent   : *~s16 Joint;
		children : []*~s16 Joint;

		local_bind_transform   : Mat4f;
		inverse_bind_transform : Mat4f;
	}

	joints : []Joint;
	root_joint : *Joint;
}

BINARY_SKELETON_FILE_VERSION :: Format_Version.{ 1, 0, 0 };

read_binary_skeleton_file :: (using skeleton : *Skeleton, reader : *Binary_Reader) -> bool
{
	match_asset_header (reader, "SkelBin");
	joints.count = expect_positive (s16, reader);
	joints.data = alloc_array (Joint, joints.count, HEAP_ALLOC);
	for * joints
	{
		it.name = expect_string (reader, count_type = s8);
		it.id = cast (s16) it_index;
		it.parent = null;
		it.children = expect_array (s16, reader, count_type = s16);
	}
	root_joint = ifx joints.count > 0 then *joints[0] else null;
	// Update parent pointers
	for * joints
	{
		for child : it.children
			child.parent = it;
	}

	calculate_skeleton_transforms (skeleton);
}

calculate_skeleton_transforms :: inline (using skeleton : *Skeleton)
{
	calculate_joint_transforms :: (using joint : *Joint, parent_transform : Mat4f)
	{
		bind_transform := local_bind_transform * parent_transform;
		inverse_bind_transform = inverse (bind_transform);
		for children
			calculate_joint_transforms (it, bind_transform);
	}

	calculate_joint_transforms (root_joint, MAT4F_IDENTITY);
}

apply_transform_to_skeleton :: inline (using skeleton : *Skeleton, transform : Mat4f)
{
	apply_transform_to_joint :: (using joint : *Joint, parent_transform : Mat4f, transform : Mat4f)
	{
		bind_transform := inverse (inverse_bind_transform) * transform;
		// Since bind_transform = local_bind_transform * parent_transform
		// then:
		local_bind_transform = bind_transform * inverse (parent_transform);
		inverse_bind_transform = inverse (bind_transform);
		for children
			apply_transform_to_joint (it, bind_transform, transform);
	}

	apply_transform_to_joint (root_joint, MAT4F_IDENTITY, transform);
}

find_joint :: inline (using skeleton : Skeleton, name : string) -> *Joint #must
{
	for * joints
		if name == it.name
			return it;

	return null;
}
