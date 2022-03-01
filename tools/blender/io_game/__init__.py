bl_info = {
	"name"     : "Mesh Importer/Exporter",
	"author"   : "ostef",
	"version"  : (1, 0, 0),
	"blender"  : (3, 0, 0),
	"location" : "File > Import/Export",
	"category" : "Import-Export",
}

# @Todo: handle separation of mesh into materials
# @Todo: handle export of multiple meshes

import bpy
from . import export_mesh
from . import export_armature

def register ():
	bpy.utils.register_class (export_mesh.Export_Mesh)
	bpy.utils.register_class (export_armature.Export_Armature)
	bpy.types.TOPBAR_MT_file_export.append (export_mesh.export_menu_func)
	bpy.types.TOPBAR_MT_file_export.append (export_armature.export_menu_func)

def unregister ():
	bpy.utils.unregister_class (export_mesh.Export_Mesh)
	bpy.utils.unregister_class (export_armature.Export_Armature)
	bpy.types.TOPBAR_MT_file_export.remove (export_mesh.export_menu_func)
	bpy.types.TOPBAR_MT_file_export.remove (export_armature.export_menu_func)

if __name__ == "__main__":
	register ()
