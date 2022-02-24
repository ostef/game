// A skinned mesh, where each vertex has at most 4 joints associated to it,
// along with the weight of each joint in the mesh deformation.

Skinned_Vertex :: struct
{
	position   : Vec3f;
	tex_coords : Vec2f;
	normal     : Vec3f;
	tangent    : Vec4f;	// XYZ = tangent vector, W = sign of bitangent: B = T.w * cross (N, T.xyz)
	joint_ids  : Vec4i;	// @Memory (stefan): Joint ids are s16, but here we use s32. We might want to change this.
	weights    : Vec3f;	// 4th weight can be deduced with W4 = 1 - (W2 + W1 + W0)

	LAYOUT :: Vertex_Buffer.Elem.[
		VEC3F,	// position
		VEC2F,	// tex_coords
		VEC3F,	// normal
		VEC4F,	// tangent
		VEC4I,	// joint_ids
		VEC3F	// weights
	];
}

Skinned_Mesh :: Mesh (Skinned_Vertex);

BINARY_SKINNED_MESH_FILE_VERSION :: Format_Version.{ 1, 0, 0 };

// This function does not initialize the mesh buffers!
read_binary_skinned_mesh_file :: (using mesh : *Skinned_Mesh, reader : *Binary_Reader) -> bool
{
	match_asset_header (reader, "MeshBin");
	vertices = expect_array (Skinned_Vertex, reader);
	indices  = expect_array (u32, reader);

	return true;
}

write_binary_skinned_mesh_file :: (using mesh : Skinned_Mesh, writer : *Binary_Writer, asset_version := Asset_Version.{})
{
	write_asset_header (writer, "MeshBin", BINARY_SKINNED_MESH_FILE_VERSION, asset_version);
	write_array (writer, vertices);
	write_array (writer, indices);
}
