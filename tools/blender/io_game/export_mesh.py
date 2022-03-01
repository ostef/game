import bpy
import bmesh
import mathutils
from bpy.props import (
	StringProperty,
	BoolProperty,
	FloatProperty
)
from bpy_extras.io_utils import (
	ExportHelper,
	orientation_helper,
	axis_conversion
)
from . import common

def rvec3 (v):
	return round (v[0], 6), round (v[1], 6), round (v[2], 6)

def rvec2 (v):
	return round (v[0], 6), round (v[1], 6)

def groups_to_tuple4 (a):
	if len (a) == 0:
		return -1, -1, -1, -1
	elif len (a) == 1:
		return a[0], -1, -1, -1
	elif len (a) == 2:
		return a[0], a[1], -1, -1
	elif len (a) == 3:
		return a[0], a[1], a[2], -1
	return a[0], a[1], a[2], a[3]

def weights_to_tuple3 (a):
	if len (a) == 0:
		return 0, 0, 0
	elif len (a) == 1:
		return round (a[0], 6), 0, 0
	elif len (a) == 2:
		return round (a[0], 6), round (a[1], 6), 0
	return round (a[0], 6), round (a[1], 6), round (a[2], 6)

def decompose_mesh_data (obj, mesh):
	bone_dict = {}
	armature_obj = obj.find_armature ()
	has_armature = armature_obj is not None
	if has_armature:
		bone_dict = common.decompose_armature_data (armature_obj.data)
	vert_group_names = { g.index : g.name for g in obj.vertex_groups }
	has_uvs = True
	if mesh.uv_layers:
		uv_layer = mesh.uv_layers.active.data
	else:
		has_uvs = False
	mesh_verts = mesh.vertices
	# We use a map of vertices to ensure we don't store the same vertices
	# multiple times. The key is a tuple of the normal and uvs, the value
	# is the index of the vertex in the mesh_verts array.
	out_verts_dict = [{} for v in range (len (mesh_verts))]
	out_verts = []
	# Mesh should be triangulated prior!
	# Array of 3 indices in out_verts.
	out_tris = [[] for p in range (len (mesh.polygons))]
	out_vert_count = 0
	for i, poly in enumerate (mesh.polygons):
		if has_uvs:
			poly_uvs = [
				uv_layer[l].uv[:]
				for l in range (poly.loop_start, poly.loop_start + poly.loop_total)
			]
		tri = out_tris[i]
		for j, vert_index in enumerate (poly.vertices):
			vert = mesh_verts[vert_index]
			if has_uvs:
				uvs = poly_uvs[j][0], poly_uvs[j][1]
			else:
				uvs = 0.0, 0.0
			normal = vert.normal[:]
			if len (vert.groups) > 4:
				print (f"Vertex {vert_index} has more than 4 groups assigned to it. Truncating.")
			if len (vert.groups) != 0 and not has_armature:
				raise Exception ("Mesh has vertices assigned to vertex groups, but we couldn't find an armature attached to it. Make sure it is parented to an armature, or it has a valid skin modifier.")
			groups = groups_to_tuple4 ([g.group for g in vert.groups])
			weights = weights_to_tuple3 ([g.weight for g in vert.groups])
			dict_local = out_verts_dict[vert_index]
			key = rvec2 (uvs), rvec3 (normal), groups, weights
			out_vert_index = dict_local.get (key)
			# If the vertex is not in the map, then add it.
			if out_vert_index is None:
				bone_ids = [-1 for i in range (len (groups))]
				for i in range (len (groups)):
					if groups[i] != -1 and vert_group_names[groups[i]] in bone_dict:
						bone_ids[i] = bone_dict[vert_group_names[groups[i]]][1]
				out_vert_index = out_vert_count
				dict_local[key] = out_vert_count
				out_verts.append ((vert_index, uvs, normal, tuple (bone_ids), weights))
				out_vert_count += 1
			tri.append (out_vert_index)
	
	return out_verts, out_tris

def write_mesh_binary (obj, mesh, filename, version = (1, 0, 0)):
	from struct import pack

	verts, tris = decompose_mesh_data (obj, mesh)
	with open (filename, "wb") as file:
		fw = file.write
		common.write_asset_header (file, version, "MeshBin\n")
		fw (pack ("<I", len (verts)))
		for index, uvs, normal, bone_ids, weights in verts:
			fw (pack ("<3f", *mesh.vertices[index].co))
			fw (pack ("<2f", *uvs))
			fw (pack ("<3f", *normal))
			fw (pack ("<4h", *bone_ids))
			fw (pack ("<3f", *weights))
		fw (pack ("<I", len (tris)))
		for tri in tris:
			fw (pack ("<3I", *tri))

def write_mesh_text (obj, mesh, filename, version = (1, 0, 0)):
	verts, tris = decompose_mesh_data (obj, mesh)
	with open (filename, "wb") as file:
		fw = file.write
		common.write_asset_header (file, version, "MeshTxt\n")
		fw (b"vertex_count %u\n" % len (verts))
		fw (b"triangle_count %u\n" % len (tris))
		for index, uvs, normal, bone_ids, weights in verts:
			fw (b"v\n")
			fw (b"%.6f %.6f %.6f\n" % mesh.vertices[index].co[:])
			fw (b"%.6f %.6f\n" % uvs)
			fw (b"%.6f %.6f %.6f\n" % normal)
			fw (b"%i %i %i %i\n" % bone_ids)
			fw (b"%.6f %.6f %.6f\n" % weights)
		for tri in tris:
			fw (b"t %u %u %u\n" % tuple (tri))

def save_mesh (
	context,
	filename,
	use_binary_format,
	use_selection,
	apply_transform,
	axis_conversion_matrix,
	version = (1, 0, 0)
):
	if bpy.ops.object.mode_set.poll ():
		bpy.ops.object.mode_set (mode = 'OBJECT')
	if use_selection:
		obs = context.selected_objects
	else:
		obs = context.scene.objects
	for ob in obs:
		try:
			me = ob.to_mesh ()
		except RuntimeError:
			continue
		# Apply object transform and calculate normals
		if apply_transform:
			me.transform (ob.matrix_world)
		if axis_conversion_matrix is not None:
			me.transform (axis_conversion_matrix.to_4x4 ())
		me.calc_normals ()
		# Triangulate mesh
		bm = bmesh.new ()
		bm.from_mesh (me)
		bmesh.ops.triangulate (bm, faces = bm.faces[:])
		bm.to_mesh (me)
		bm.free ()
		if use_binary_format:
			write_mesh_binary (ob, me, filename, version)
		else:
			write_mesh_text (ob, me, filename, version)
		ob.to_mesh_clear ()
		print (f"Exported mesh {ob.name} to file {filename}.\n")

# By default, we use -Z forward because even though our coordinate system
# uses Z forward and Y up, our meshes face backwards in blender because
# it is easier to work with.
@orientation_helper (axis_forward = '-Z', axis_up = 'Y')
class Export_Mesh (bpy.types.Operator, ExportHelper):
	"""Export geometry mesh data for use in the Game."""
	bl_idname = "export.game_mesh"
	bl_label = "Export Mesh (.mesh)"
	bl_options = { 'REGISTER', 'UNDO' }
	filename_ext = ".mesh"

	use_binary_format : BoolProperty (
		name = "Export as binary",
		description = "Export the mesh as binary data.",
		default = True
	)
	use_selection : BoolProperty (
		name = "Only selected",
		description = "Export only the selected meshes.",
		default = False
	)
	apply_transform : BoolProperty (
		name = "Apply object transform",
		description = "Apply the object transform matrix when exporting meshes.",
		default = True
	)

	def execute (self, context):
		context.window.cursor_set ('WAIT')
		save_mesh (
			context,
			self.filepath,
			self.use_binary_format,
			self.use_selection,
			self.apply_transform,
			axis_conversion (to_forward = self.axis_forward, to_up = self.axis_up)
		)
		context.window.cursor_set ('DEFAULT')

		return { 'FINISHED' }

def export_menu_func (self, context):
	self.layout.operator (Export_Mesh.bl_idname)
