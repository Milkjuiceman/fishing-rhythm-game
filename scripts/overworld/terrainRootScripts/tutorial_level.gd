extends Node3D

@onready var spawn_points = $SpawnPoints

func _ready():
	# Check if this is the very first time ever spawning the player
	if not BoatManager.has_spawned_before:
		# First time - set initial spawn position
		var initial_spawn = $SpawnPoints/tutorial_boat_initial_spawnpoint
		BoatManager.player_position = initial_spawn.global_transform.origin
		BoatManager.player_rotation = Vector3(0, initial_spawn.rotation.y, 0)
	
	# Load the player (with boat) into this scene
	var player = BoatManager.load_player_into_scene(spawn_points)
	add_child(player)
	
	# After player is in the scene, check if we need to swap to a different boat
	if BoatManager.current_boat_scene_path != "":
		_swap_to_saved_boat(player)

func _swap_to_saved_boat(player: Player):
	var boat_scene_path = BoatManager.current_boat_scene_path
	
	if not ResourceLoader.exists(boat_scene_path):
		print("Warning: Saved boat scene not found: " + boat_scene_path)
		return
	
	var boat_scene = load(boat_scene_path)
	
	# Remove the current boat
	if player.current_vehicle:
		player.current_vehicle.queue_free()
	
	# Add the saved boat type
	var new_boat = boat_scene.instantiate()
	player.add_child(new_boat)
	
	# Update player references
	player.current_vehicle = new_boat
	player.current_vehicle.player = player
	player.detection_area = new_boat.get_detection_area()
	
	# Fix water height
	if new_boat.has_method("update_water_lock"):
		await get_tree().process_frame
		new_boat.update_water_lock()
