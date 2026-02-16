extends Control

signal shop_closed

# Preload the different boat scenes - make sure these point to .tscn files, not .gd files!
# Update these paths to match where your actual boat SCENE files are located
var boat_scene = preload("res://scenes/overworld/boats/boat.tscn")
var big_boat_scene = preload("res://scenes/overworld/boats/boatBig.tscn")

func _ready():
	# Make sure shop works while game is paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Show mouse cursor when shop opens
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# Connect button signals
	$VBoxContainer/Boat.pressed.connect(_on_boat_selected)
	$VBoxContainer/BigBoat.pressed.connect(_on_big_boat_selected)
	$VBoxContainer/Back.pressed.connect(_on_back_pressed)

func _on_boat_selected():
	print("Small boat selected!")
	switch_to_boat(boat_scene)

func _on_big_boat_selected():
	print("Big boat selected!")
	switch_to_boat(big_boat_scene)

func switch_to_boat(new_boat_scene: PackedScene):
	# Get the current player instance
	var current_player = BoatManager.player_instance
	
	if current_player == null:
		print("Error: No player instance found!")
		return
	
	# Get the spawn point from the main scene
	var main_scene = get_tree().current_scene
	var spawn_point = main_scene.get_node_or_null("SpawnPoints/tutorial_boat_upgrade_spawnpoint")
	
	if spawn_point == null:
		print("Error: Spawn point not found!")
		return
	
	# Save the spawn position
	var spawn_position = spawn_point.global_position
	var spawn_rotation = spawn_point.rotation
	
	# Remove the old boat from the player
	if current_player.current_vehicle:
		current_player.current_vehicle.queue_free()
	
	# Create the new boat
	var new_boat = new_boat_scene.instantiate()
	current_player.add_child(new_boat)
	
	# Move the player to the spawn point
	current_player.global_position = spawn_position
	current_player.rotation = spawn_rotation
	
	# Update the player's current vehicle reference
	current_player.current_vehicle = new_boat
	current_player.current_vehicle.player = current_player
	current_player.detection_area = new_boat.get_detection_area()
	
	# Save the boat type to BoatManager so it persists
	if new_boat.scene_file_path:
		BoatManager.current_boat_scene_path = new_boat.scene_file_path
	
	# Fix water height after spawning - defer to next frame
	if new_boat.has_method("update_water_lock"):
		new_boat.call_deferred("update_water_lock")
	
	# Close the shop
	close_shop()

func _on_back_pressed():
	print("Back button pressed")
	close_shop()

func close_shop():
	# Hide mouse cursor when returning to gameplay
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# Emit the signal so the detection area knows to unpause
	shop_closed.emit()
	
	# Note: Don't queue_free here, let the signal handler do it
	# queue_free()
