bl_info = {
	"name" : "Game Mesh Format",
	"author" : "ostef",
	"version" : (1, 0, 0),
	"blender": (3, 0, 0),
	"location" : "File > Import/Export",
	"description" : "Import/Export mesh data for use in the Game. Always import/export position, UVs, normal, and skinning data.",
	"category" : "Import-Export"
}

import bpy
from bpy.props import (
	CollectionProperty,
	StringProperty,
	BoolProperty,
	FloatProperty,
)
from bpy_extras.io_utils import (
	ImportHelper,
	ExportHelper,
	axis_conversion,
	orientation_helper,
)

#class Import_Mesh (bpy.types.Operator, ImportHelper):
#	"""Load a Mesh geometry file"""
#	bl_idname = "import_mesh.mesh"
#	bl_label = "Import Mesh"
#	bl_options { 'REGISTER', 'UNDO' }
#	filename_ext = ".mesh"
#
#	files : CollectionProperty (
#		name = "File Path",
#		description = "File path used for importing the Mesh file",
#		type = bpy.types.OperatorFileListElement
#	)
#
#	def execute (self, context):
#		import os
#		from . import import_mesh
#		context.window.cursor_set ('WAIT')
#		filenames = [
#			os.path.join (self.directory, name.name) for name in self.files
#		]
#		if not filenames:
#			filenames.append (self.filepath)
#		for filename in filenames
#			import_ply.load (self, context, filename)
#		context.window.cursor_set ('DEFAULT')
#
#		return { 'FINISHED' }

@orientation_helper (axis_forward = 'Z', axis_up = 'Y')
class Export_Mesh (bpy.types.Operator, ExportHelper):
	bl_idname = "export_mesh.mesh"
	bl_label = "Export Mesh"
	bl_description = "Export as Game Mesh with position, UVs, normals and skinning information."
	filename_ext = ".mesh"

	filename : StringProperty ()
	use_selection : BoolProperty (
		name = "Only Selected",
		description = "Export selected objects only. If disabled, all scene objects will get exported.",
		default = True,
	)
	use_mesh_modifiers : BoolProperty (
		name = "Apply Modifiers",
		description = "Apply Modifiers to the exported meshes",
		default = False,
	)

	def execute (self, context):
		import os
		from . import export_mesh
		context.window.cursor_set ('WAIT')
		filenames = [
			os.path.join (self.directory, name.name) for name in self.files
		]
		if not filenames:
			filenames.append (self.filepath)
		for filename in filenames:
			export_mesh.save (self, context, filename)
		print (f"Exported {filename!r}");
		context.window.cursor_set ('DEFAULT')

		return { 'FINISHED' }

#def menu_func_import (self, context):
#	self.layout.operator (Import_Mesh.bl_idname, text = "Game Mesh (.mesh)")

def menu_func_export (self, context):
	self.layout.operator (Export_Mesh.bl_idname, text = "Game Mesh (.mesh)")

classes = (
#	Import_Mesh,
	Export_Mesh,
)

def register ():
	for cls in classes:
		bpy.utils.register_class (cls)
#	bpy.types.TOPBAR_MT_file_import.append (menu_func_import)
	bpy.types.TOPBAR_MT_file_export.append (menu_func_export)

def unregister ():
	for cls in classes:
		bpy.utils.unregister_class (cls)
#	bpy.types.TOPBAR_MT_file_import.remove (menu_func_import)
	bpy.types.TOPBAR_MT_file_export.remove (menu_func_export)

if __name__ == "__main__":
	register ()
