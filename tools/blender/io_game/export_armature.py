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
from bpy.types import (
	Context,
	Armature
)
from typing import (
	List,
	Dict,
	Tuple,
	BinaryIO
)
from . import common

def write_armature_binary (armature : Armature, filename : str, version : Tuple[int, int, int] = (1, 0, 0)):
	from struct import pack

	bones_dict, bones = common.decompose_armature_data (armature)
	with open (filename, "wb") as file:
		fw = file.write
		common.write_asset_header (file, version, "SkelBin\n")
		fw (pack ("<h", len (bones)))	# Joint count, maximum is s16 max
		for b in bones:
			if b.parent is not None:
				local_transform = b.parent.matrix_local.inverted () @ b.matrix_local
			else:
				local_transform = b.matrix_local
			bone_name = b.name
			if len (bone_name) > 255:
				print (f"Bone {bone_name} has a name that exceeds 255 characters, truncating...\n")
				bone_name = b.name[0:255]
			fw (pack ("<B", len (bone_name)))	# Joint name length, maximum 255 bytes
			fw (b"%s" % bytes (bone_name, 'UTF-8'))
			fw (pack ("<4f", *local_transform[0]))
			fw (pack ("<4f", *local_transform[1]))
			fw (pack ("<4f", *local_transform[2]))
			fw (pack ("<4f", *local_transform[3]))
			deform_child_count = 0
			for child in b.children:
				if child.use_deform:
					deform_child_count += 1
			fw (pack ("<h", deform_child_count))	# Child count, maximum is s16 max
			for child in b.children:
				if child.use_deform:
					fw (pack ("<h", bones_dict[child.name]))

def write_armature_text (armature : Armature, filename : str, version : Tuple[int, int, int] = (1, 0, 0)):
	bones_dict, bones = common.decompose_armature_data (armature)
	with open (filename, "wb") as file:
		fw = file.write
		common.write_asset_header (file, version, "SkelTxt\n")
		fw (b"joint_count %u\n" % len (bones))
		for b in bones:
			fw (b"joint %s\n" % bytes (b.name, 'UTF-8'))
			fw (b"local_bind_transform\n")
			if b.parent is not None:
				local_transform = b.parent.matrix_local.inverted () @ b.matrix_local
			else:
				local_transform = b.matrix_local
			fw (b"%.6f %.6f %.6f %.6f\n" % local_transform[0][:])
			fw (b"%.6f %.6f %.6f %.6f\n" % local_transform[1][:])
			fw (b"%.6f %.6f %.6f %.6f\n" % local_transform[2][:])
			fw (b"%.6f %.6f %.6f %.6f\n" % local_transform[3][:])
			deform_child_count = 0
			for child in b.children:
				if child.use_deform:
					deform_child_count += 1
			fw (b"child_count %u\n" % deform_child_count)
			for child in b.children:
				if child.use_deform:
					fw (b"%u " % bones_dict[child.name])
			fw (b"\n")

def save_armature (
	context : Context,
	filename : str,
	use_binary_format : bool,
	use_selection : bool,
	apply_transform : bool,
	axis_conversion_matrix : mathutils.Matrix,
	version : Tuple[int, int, int] = (1, 0, 0)
):
	if bpy.ops.object.mode_set.poll ():
		bpy.ops.object.mode_set (mode = 'OBJECT')
	if use_selection:
		obs = context.selected_objects
	else:
		obs = context.scene.objects
	for ob in obs:
		if ob.type == 'ARMATURE':
			armature_obj = ob
		else:
			armature_obj = ob.find_armature ()
		if armature_obj is None:
			continue
		armature = armature_obj.data.copy ()
		# Apply object transform and calculate normals
		if apply_transform:
			armature.transform (ob.matrix_world)
		if axis_conversion_matrix is not None:
			armature.transform (axis_conversion_matrix.to_4x4 ())
		# Triangulate mesh
		if use_binary_format:
			write_armature_binary (armature, filename, version)
		else:
			write_armature_text (armature, filename, version)
		print (f"Exported armature {ob.name} to file {filename}.\n")

# By default, we use -Z forward because even though our coordinate system
# uses Z forward and Y up, our meshes face backwards in blender because
# it is easier to work with.
@orientation_helper (axis_forward = '-Z', axis_up = 'Y')
class Export_Armature (bpy.types.Operator, ExportHelper):
	"""Export armature data for use in the Game."""
	bl_idname = "export.game_armature"
	bl_label = "Export Armature/Skeleton (.skel)"
	bl_options = { 'REGISTER', 'UNDO' }
	filename_ext = ".skel"

	use_binary_format : BoolProperty (
		name = "Export as binary",
		description = "Export the armature as binary data.",
		default = True
	)
	use_selection : BoolProperty (
		name = "Only selected",
		description = "Export only the selected armatures.",
		default = True
	)
	apply_transform : BoolProperty (
		name = "Apply object transform",
		description = "Apply the object transform matrix when exporting armatures.",
		default = True
	)

	def execute (self, context : Context):
		context.window.cursor_set ('WAIT')
		save_armature (
			context,
			self.filepath,
			self.use_binary_format,
			self.use_selection,
			self.apply_transform,
			axis_conversion (to_forward = self.axis_forward, to_up = self.axis_up)
		)
		context.window.cursor_set ('DEFAULT')
		
		return { 'FINISHED' }

def export_menu_func (self, context : Context):
	self.layout.operator (Export_Armature.bl_idname)
