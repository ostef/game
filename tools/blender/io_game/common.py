def write_asset_header (file, version, format_identifier):
	import datetime

	fw = file.write
	fw (bytes (format_identifier, 'UTF-8'))
	fw (b"%u.%u.%u\n" % version)
	now = datetime.datetime.now ()
	now_str = now.strftime ("%Y:%m:%d.%H:%M:%S\n")
	fw (bytes (now_str, 'UTF-8'))

"""
For now, we don't care about the root bone. Our engine does though, so we'll have to revert to
how we did things before, it's just, Rigify has a very weird joint hierarchy, so we should either
ditch that rig or do something akin to Rigify To Unity, which I honestly don't want to bother
doing considering we will probably use our own rigs in the future for serious projects.
"""
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

	"""
	root = None # The root bone does not have to be a deform bone. Rigify for example, does not have a deform root bone.
	# Find root bone
	for b in armature.bones:
		if b.parent is None and (b.use_deform or has_deform_children (b)):
			if root is not None:
				raise Exception ("Found multiple root bones in armature.")
			root = b
	if root is None:
		raise Exception ("Could not find root bone.")
	"""
	bones_dict = {}
	bones = []
	#append_bone (root, bones)
	for b in armature.bones:
		if b.use_deform:
			deform_child_count = 0
			for child in b.children:
				if child.use_deform:
					deform_child_count += 1
			if deform_child_count > 32767:
				raise Exception (f"Armature bone {b.name} has more than 32767 deform children (it has {deform_child_count}).")
			bones_dict.update ({ b.name : len (bones) })
			bones.append (b)
	if len (bones) > 32767:
		raise Exception (f"Armature has more than 32767 deform bones (it has {len (bones)} bones).")

	return bones_dict, bones
