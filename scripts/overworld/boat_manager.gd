extends Node

var player_scene = preload("res://scenes/player/player.tscn")  
var player_instance = null
var player_position = Vector3.ZERO
var player_rotation = Vector3.ZERO
var target_spawn_point = ""  # Which entrance to use in the next scene
var return_scene_path = ""  # Store which scene to return to after minigames
var has_spawned_before = false  # Track if player has ever been created
var current_boat_scene_path = ""  # Track which boat type the player is using

func save_player_state(player: Player):
	player_position = player.get_current_position()
	player_rotation = player.get_current_rotation()
	
	# Save which boat type the player is currently using
	if player.current_vehicle:
		current_boat_scene_path = player.current_vehicle.scene_file_path

func set_transition(scene_path: String, spawn_point_name: String):
	target_spawn_point = spawn_point_name
	return_scene_path = scene_path  # Save the scene we're transitioning from

func load_player_into_scene(spawn_points_parent):
	if player_instance:
		player_instance.queue_free()
	
	player_instance = player_scene.instantiate()
	
	# Mark that we've spawned the player at least once
	has_spawned_before = true
	
	# If we have a target spawn point, use it
	if target_spawn_point != "":
		var spawn_point = spawn_points_parent.get_node_or_null(target_spawn_point)
		if spawn_point and spawn_point.is_inside_tree():
			# Use position, not global_transform (player isn't in tree yet)
			player_instance.position = spawn_point.global_position
			player_instance.rotation.y = spawn_point.rotation.y
		target_spawn_point = ""  # Reset after use
	else:
		# Otherwise use saved position
		player_instance.position = player_position
		player_instance.rotation = player_rotation
	
	return player_instance

# Update in the future
# Old code might call this
func save_boat_state(boat):
	if boat.player:
		save_player_state(boat.player)	
