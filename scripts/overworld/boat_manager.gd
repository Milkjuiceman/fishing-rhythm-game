extends Node

var boat_scene = preload("res://scenes/overworld/boat.tscn")  
var boat_instance = null
var boat_position = Vector3.ZERO
var boat_rotation = Vector3.ZERO
var target_spawn_point = ""  # Which entrance to use in the next scene

func save_boat_state(boat):
	boat_position = boat.global_transform.origin
	boat_rotation = boat.rotation

func set_transition(scene_path: String, spawn_point_name: String):
	target_spawn_point = spawn_point_name

func load_boat_into_scene(spawn_points_parent):
	if boat_instance:
		boat_instance.queue_free()
	
	boat_instance = boat_scene.instantiate()
	
	# If we have a target spawn point, use it
	if target_spawn_point != "":
		var spawn_point = spawn_points_parent.get_node_or_null(target_spawn_point)
		if spawn_point:
			boat_instance.global_transform.origin = spawn_point.global_transform.origin
			boat_instance.rotation.y = spawn_point.rotation.y
		target_spawn_point = ""  # Reset after use
	else:
		# Otherwise use saved position
		boat_instance.global_transform.origin = boat_position
		boat_instance.rotation = boat_rotation
	
	return boat_instance
