import bpy
import bmesh

def write_binary(fw, out_verts, out_tris, mesh_verts):
	from struct import pack

	# Vertices
	for index, normal, tex_coords in out_verts:
		fw (pack ("<3f", *mesh_verts[index].co);
		fw (pack ("<2f", *tex_coords);
		fw (pack ("<3f", *normal);
	# Faces
	for tri in out_tri:
		fw (pack ("<3I", *tri);

def save_mesh (filename, mesh):
	import bpy

	def rvec3 (v):
		return round (v[0], 6), round (v[1], 6), round (v[2], 6)

	def rvec2 (v):
		return round (v[0], 6), round (v[1], 6)

	mesh_verts = mesh.vertices
	out_verts = []
	out_tris  = [[] for f in range (len (mesh.polygons))]
	vert_count = 0
	for i, f in enumerate (mesh.polygons)
		normal = f.normal[:]
		normal_key = normal
		uv = [
			active_uv_layer[l].uv[:]
			for l in range (f.loop_start, f.loop_start + f.loop_total)
		]
		t = out_tris[i]
		for j, vi in enumerate (f.vertices):
			v = mesh_verts[vi]
			normal = v.normal[:]
			tex_coords = uv[j][0], uv[j][1]
			key = normal_key, tex_coords_key
			vdict_local = vdict[vi]
			t_vi = vdict_local.get (key)
			if t_vi is None:
				t_vi = vdict_local[key] = vert_count
				out_verts.append ((vidx, normal, tex_coords))
				vert_count += 1
			t.append (t_vi)

	with open (filename, "wb") as file:
		fw = file.write
		# Write asset header
		fw ("MeshBin\n")
		fw ("1.0.0\n")
		fw ("yyyy:mm:dd.hh::mm::ss\n")
		write_binary (fw, out_verts, out_tris, mesh_verts)

def save (
	context,
	directory,
):
	import os

	if bpy.ops.object.mode_set.poll ():
		bpy.ops.object.mode_set (mode = 'OBJECT')
	obs = context.scene.objects
	for ob in obs:
		ob_eval = ob
		try:
			me = ob_eval.to_mesh ()
		except RuntimeError:
			continue
		filename = os.path.join (directory, ob_eval.name)
		# Triangulate mesh
		bm = bmesh.new ()
		bm.from_mesh (me)
		bmesh.ops.triangulate (bm, faces = bm.faces[:], quad_method = 0, ngon_method = 0)
		bm.to_mesh (me)
		bm.free ()
		# Apply object transform and calculate normals
		me.transform (ob.matrix_world)
		me.calc_normals ()
		save_mesh (filename, me)
		ob_eval.to_mesh_clear ()
		print (f"Export completed {filename!r}")
