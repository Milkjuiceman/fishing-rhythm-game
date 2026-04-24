@tool
extends EditorScenePostImport

## Basic Multipurpose Import Script
## Made by Qualia with <3
## Source: https://gist.github.com/Qualia765/92c931f9a03e5f9142e63667605ddea3
## Copyright Qualia Farrell 2026 under MIT License https://mit-license.org/

## === Objectives ===
## -> Change a property when an object is imported into godot automatically based on custom property in blender
## -> Allow for using multimesh

## === How to use ===
## == Set Property ==
##     In blender on something scroll to the bottom
##     in "Custom Properties" select "New"
##     Click the gear icon next to
##     Change the Property Name to "import_X" where X is the name of the property in godot
##     Change the Type to the data type of that property that it in Godot
##     Select "Ok"
##     Enter the value that you want the value to be set when it is imported
##
## == Export ==
##     When you export as a glb/gltf make sure the option Include > Data > Custom Properties is checked on
##     In Godot select the glb/gltf in the FileSystem
##     In the Import Tab, find "Import Script" and then select this script
##     Choose Reimport

## === Supported Custom Property Locations ===
## == Yes ==
## Object/Nodes (Object Properties Tab in Blender)
## Materials (Material Tab in Blender)
## Meshes (Data Tab in Blender)
## == No ==
## Bones - im lazy - idk why you wold need this
## Actions/Animations - a godot bug prevents this
##    There are other native ways to do this:
##    Such as append "-loop" to the end of an action's name to make it loop
##    You can also use Advanced Import Settings to modify these properties

## === Supported Data types ===
## -> bool
## -> int
## -> float
## -> String
## -> StringName (use string)
## -> Vector2-4 (use a float array of 2-4 values)
## -> Vector2-4i (use an int array of 2-4 values)
## -> Transform2D (use float array of 6 values)
## -> Transform3D (use float array of 12 values)

## === Instancing ===
## Export Settings > Data > Scene Graph > GPU Instances: DISABLED
## == Not using Geo Nodes: ==
##     An empty with a number of children meshes
##     Add "multimesh" custom property to the empty
##
## == Using geometry nodes ==
##     Export Settings > Data > Scene Graph > Geometry Node Instances: ENABLED
##     Export Settings > Data > Mesh > Apply Modifiers: ENABLED
##     Add "multimesh" custom property to the the object with the geonodes
##     The last node before the output should be an "Instance on Points Node"



# entry
func _post_import(scene: Node):
	iterate(scene)
	return scene

# recurse through all nodes
func iterate(node: Node):
	if node == null: return
	
	# instancing
	if should_apply_instancing(node):
		var replacement := generate_multimesh(node)
		read_extras_and_apply(replacement) # object imports
		apply_to_mesh(replacement.multimesh.mesh)
		
	else:
		read_extras_and_apply(node) # object imports
		if node is MeshInstance3D:
			apply_to_mesh(node.mesh)
		
		for child in node.get_children():
			iterate(child)


func apply_to_mesh(mesh: Mesh):
	read_extras_and_apply(mesh) # mesh imports
	for surface_index in mesh.get_surface_count():
		var material : StandardMaterial3D = mesh.surface_get_material(surface_index)
		read_extras_and_apply(material) # material imports


func read_extras_and_apply(thing: Object):
	# Blender's custom properties exported to in Godot are saved in
	# the meta of a object, in a dictionary named extras
	if thing.has_meta(&"extras"):
		var extras: Dictionary = thing.get_meta(&"extras")

		for extra: String in extras:
			if extra.begins_with("import_"):
				var property = extra.substr(7)
				thing[property] = convert_to_better_format(extras[extra])
				# delete it as if it was never here
				extras.erase(extra)

		# delete it as if it was never here
		if extras.is_empty():
			thing.remove_meta(&"extras")


func convert_to_better_format(original: Variant) -> Variant:
	if original is Array:
		if original[0] is int:
			match original.size():
				2: return Vector2i(original[0], original[1])
				3: return Vector3i(original[0], original[1], original[2])
				4: return Vector4i(original[0], original[1], original[2], original[3])
		elif original[0] is float:
			match original.size():
				2: return Vector2(original[0], original[1])
				3: return Vector3(original[0], original[1], original[2])
				4: return Vector4(original[0], original[1], original[2], original[3])
				6: return Transform2D(
						Vector2(original[0],original[1]),
						Vector2(original[2],original[3]),
						Vector2(original[4],original[5])
					)
				12: return Transform3D(
						Vector3(original[0], original[1], original[2]),
						Vector3(original[3], original[4], original[5]),
						Vector3(original[6], original[7], original[8]),
						Vector3(original[9], original[10], original[11]),
					)
	return original


## determine if elgeble for instancing
func should_apply_instancing(node: Node) -> bool:
	#return false
	if not node.has_meta(&"extras"): return false
	var extras: Dictionary = node.get_meta(&"extras")
	if not extras.has(&"multimesh"): return false
	if node.get_child_count() == 0: return false
	return true



## potentially make a multimesh based on described above
func generate_multimesh(node: Node) -> MultiMeshInstance3D:
	# Make multimesh
	var multimesh := MultiMesh.new()
	multimesh.instance_count = 0
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = node.get_child(0).mesh

	# Set count
	var count: int = 0
	for child in node.get_children():
		if child is Node3D:
			count += 1
		else:
			push_warning("Expected children of a MeshInstance3D with instances enabled to all be Node3Ds")

	multimesh.instance_count = count

	# Transfer data
	var index: int = 0
	for child in node.get_children():
		multimesh.set_instance_transform(index, child.transform)
		index += 1

	# Make multimesh instance
	var multi_mesh_instance := MultiMeshInstance3D.new()
	multi_mesh_instance.multimesh = multimesh

	# Transfer various stuff
	# I think this is all the important stuff
	multi_mesh_instance.transform = node.transform
	multi_mesh_instance.visible = node.visible
	multi_mesh_instance.rotation_order = node.rotation_order

	# Transfer meta
	for meta_key in node.get_meta_list():
		multi_mesh_instance.set_meta(meta_key, node.get_meta(meta_key))

	# infanticide
	for child in node.get_children(true):
		node.remove_child(child)
		child.free()
	# transfer
	node.replace_by(multi_mesh_instance)
	# suicide
	node.free()

	return multi_mesh_instance
