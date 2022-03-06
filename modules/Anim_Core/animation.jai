Skeleton_Pose :: struct
{
	Joint :: struct
	{
		position : Vec3f;
		orientation : Quatf;
		scale : Vec3f;
		model_space_transform : Mat4f;
	}

	skeleton : *Asset (Skeleton);
	joints : []Joint;
}

Sampled_Animation :: struct
{
	Joint_Sample :: struct
	{
		position : Vec3f;
		orientation : Quatf;
		scale : Vec3f;
		time  : f32;
	}

	skeleton : *Asset (Skeleton);
	duration : f32;
	frames : [][]Joint_Sample;	// [joint_id][frame_index]
}

Interpolation_Method :: enum
{
	NEAREST :: 0;
	LINEAR  :: 1;
}

BINARY_ANIMATION_FILE_VERSION :: Format_Version.{ 1, 0, 0 };

read_binary_animation_file :: (using animation : *Sampled_Animation, reader : *Binary_Reader) -> bool
{
	expect_asset_header (reader, "AnimBin");
	skeleton_name := clone_string (expect_string (reader), HEAP_ALLOC);
	skeleton = load_asset (Skeleton, skeleton_name);
	if !skeleton
		return false;
	duration = expect (f32, reader);
	frames.count = expect_positive (s16, reader);
	frames.data = alloc_array ([]Sampled_Animation.Joint_Sample, frames.count, HEAP_ALLOC);
	for * frames
		it = expect_array (Sampled_Animation.Joint_Sample, reader);

	return true;
}

init_pose :: inline (pose : *Skeleton_Pose, skeleton : *Skeleton, allocator : Allocator)
{
	pose.skeleton = skeleton;
	pose.joints = alloc_array (pose.Joint, skeleton.joints.count, allocator);
}

destroy_pose :: inline (pose : *Skeleton_Pose, allocator : Allocator)
{
	free (pose.joints, allocator);
	pose.joints = .[];
	pose.skeleton = null;
}

calculate_pose_transforms :: inline (using pose : *Skeleton_Pose)
{
	calculate_joint_transforms :: (pose : *Skeleton_Pose, skeleton_joint : *Skeleton.Joint, parent_transform : Mat4f)
	{
		using joint_pose := *pose.joints[skeleton_joint.id];
		local_transform := mat4f_transform (position, orientation, scale);
		model_space_transform = local_transform * parent_transform;
		for children
			calculate_joint_transforms (pose, it, model_space_transform);
	}

	calculate_joint_transforms (pose, skeleton.root, MAT4F_IDENTITY);
}

apply_transform_to_pose :: inline (using pose : *Skeleton_Pose, transform : Mat4f)
{
	apply_transform_to_joint :: (
		pose : *Skeleton_Pose,
		skeleton_joint : *Skeleton.Joint,
		new_parent_transform : Mat4f,
		transform : Mat4f
	)
	{
		using joint_pose := *pose.joints[skeleton_joint.id];
		model_space_transform *= transform;	// Not sure if this actually does A = A * B...
		local_transform = model_space_transform * inverse (new_parent_transform);
		// Extract the components from the transform local_transform
		position = translation_vector (local_transform);
		orientation = to_quaternion (local_transform);
		scale = scale_vector (local_transform);
		for skeleton_joint.children
			apply_transform_to_joint (pose, it, model_space_transform, transform);
	}

	apply_transform_to_joint (pose, skeleton.root, MAT4F_IDENTITY, transform);
}

set_to_bind_pose :: inline (using pose : *Skeleton_Pose)
{
	for * joints
	{
		it.position = translation_vector (skeleton.joints[it_index].local_bind_transform);
		it.orientation = to_quaternion (skeleton.joints[it_index].local_bind_transform);
		it.scale = scale_vector (skeleton.joints[it_index].local_bind_transform);
	}
}

generate_skinning_matrices :: inline (using pose : *Skeleton_Pose, allocator : Allocator) -> []Mat4f #must
{
	calculate_pose_transforms (pose);
	result := alloc_array (Mat4f, joints.count, allocator);
	for * result
	{
		<<it = skeleton.joints[i].inverse_bind_transform * joints[i].model_space_transform;
	}

	return result;
}
