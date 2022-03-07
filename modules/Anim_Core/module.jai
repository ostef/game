#import "Core";
#import "Linalg";
#import "Render_Core";
#import "Asset";
#import "Binary_Reader";
#import "File_System";

#load "mesh.jai";
#load "skeleton.jai";
#load "animation.jai";

#scope_module

load_binary_asset_file :: inline (asset : *T, filename : string, $read_function : (*$T, *Binary_Reader) -> bool) -> bool
{
	file_contents, ok := read_entire_file (filename, HEAP_ALLOC);
	if !ok
		return log_error ("Could not read file '%'.", filename);
	defer free (file_contents, HEAP_ALLOC);
	reader : Binary_Reader;
	init_binary_reader (*reader, file_contents);

	return read_function (asset, *reader);
}

#scope_export

init_anim_core_asset_caches :: inline ()
{
	init_asset_cache (*skeleton_assets, load_binary_skeleton_file, cleanup_skeleton);
	init_asset_cache (*skinned_mesh_assets, load_binary_skinned_mesh_file, cleanup_skinned_mesh);
}
