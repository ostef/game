def write_asset_header (file, version, format_identifier):
	import datetime

	fw = file.write
	fw (bytes (format_identifier, 'UTF-8'))
	fw (b"%u.%u.%u\n" % version)
	now = datetime.datetime.now ()
	now_str = now.strftime ("%Y:%m:%d.%H:%M:%S\n")
	fw (bytes (now_str, 'UTF-8'))

def decompose_armature_data (armature):
	def append_bone (bone, bones):
		bones.update ({ bone.name : (bone, len (bones)) })
		for child in bone.children:
			if child.use_deform:
				append_bone (child, bones)

	def has_deform_children (bone):
		for child in bone.children:
			if child.use_deform:
				return True
		return False

	root = None # The root bone does not have to be a deform bone. Rigify for example, does not have a deform root bone.
	# Find root bone
	for b in armature.bones:
		if b.parent is None and (b.use_deform or has_deform_children (b)):
			if root is not None:
				raise Exception ("Found multiple root bones in armature.")
			root = b
	if root is None:
		raise Exception ("Could not find root bone.")
	bones = {}
	append_bone (root, bones)

	return bones
