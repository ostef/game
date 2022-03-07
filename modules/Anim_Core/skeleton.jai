#import "Debug_Draw";
#import "Math";

Skeleton :: struct
{
	Joint :: struct
	{
		name     : string;
		id       : s16;
		parent   : *Joint;
		children : []*Joint;

		local_bind_transform   : Mat4f;
		inverse_bind_transform : Mat4f;
	}

	joints : []Joint;
	root_joint : *Joint;
}

skeleton_assets : Asset_Cache (Skeleton);

BINARY_SKELETON_FILE_VERSION :: Format_Version.{ 1, 0, 0 };

load_binary_skeleton_file :: #bake_arguments load_binary_asset_file (read_function = read_binary_skeleton_file);

cleanup_skeleton :: (using skeleton : *Skeleton)
{
	for * joints
	{
		free (it.name, HEAP_ALLOC);
		free (it.children, HEAP_ALLOC);
	}
	free (joints, HEAP_ALLOC);
	joints = .[];
	root_joint = null;
}

read_binary_skeleton_file :: (using skeleton : *Skeleton, reader : *Binary_Reader) -> bool
{
	expect_asset_header (reader, "SkelBin");
	joints.count = expect_positive (reader, s16);
	joints = alloc_array (Joint, joints.count, HEAP_ALLOC, initialize = true);
	for * joints
	{
		it.name = clone_string (expect_string (reader, count_type = s8), HEAP_ALLOC);
		it.id = cast (s16) it_index;
		it.local_bind_transform = expect (reader, Mat4f);
		it.children.count = expect_positive (reader, s16);
		it.children = alloc_array (*Joint, it.children.count, HEAP_ALLOC);
		for i : 0..it.children.count - 1
		{
			child_id := expect_positive (reader, s16);
			it.children[i] = *joints[child_id];
			it.children[i].parent = it;
		}
	}
	root_joint = ifx joints.count > 0 then *joints[0] else null;
	calculate_skeleton_transforms (skeleton);

	return true;
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

find_joint :: inline (using skeleton : Skeleton, name : string) -> *Skeleton.Joint #must
{
	for * joints
		if name == it.name
			return it;

	return null;
}

debug_draw_skeleton :: inline (using skeleton : Skeleton, color : RGBA, transform := MAT4F_IDENTITY)
{
	debug_draw_joint :: (joint : *Joint, size : f32, transform : Mat4f, color : RGBA) -> joint_position : Vec3f
	{
		model_space_transform := inverse (joint.inverse_bind_transform);
		world_space_transform := model_space_transform * transform;
		start := translation_vector (world_space_transform);
		for child : joint.children
		{
			end := debug_draw_joint (child, size, transform, color);
			debug_draw_line (start, end, color);
		}
		debug_draw_coordinates (world_space_transform, size);

		return start;
	}

	scale := scale_vector (transform);
	size := length (scale) * 0.01;
	debug_draw_joint (root_joint, size, transform, color);
}
