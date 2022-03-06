// A skinned mesh, where each vertex has at most 4 joints associated to it,
// along with the weight of each joint in the mesh deformation.

Skinned_Vertex :: struct
{
	position   : Vec3f;
	tex_coords : Vec2f;
	normal     : Vec3f;
	tangent    : Vec4f;	// XYZ = tangent vector, W = sign of bitangent: B = T.w * cross (N, T.xyz)
	joint_ids  : [4]s16;
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
	expect_asset_header (reader, "MeshBin");
	vertices.count = expect (reader, u32);
	vertices.data = alloc (size_of (Skinned_Vertex) * vertices.count, HEAP_ALLOC);
	for * vert : vertices
	{
		vert.position   = expect (reader, Vec3f);
		vert.tex_coords = expect (reader, Vec2f);
		vert.normal     = expect (reader, Vec3f);
		// tangent is calculated by us!
		vert.joint_ids = expect (reader, [4]s16);
		vert.weights   = expect (reader, Vec3f);
	}
	indices  = expect_array (reader, u32);

	return true;
}
