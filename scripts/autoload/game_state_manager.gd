extends Node
## Game State Manager (Autoload Singleton)
## Centralized management of player state, scene transitions, and save/load operations
## Replaces old BoatManager with scalable, persistent state management across entire game

# ========================================
# SIGNALS
# ========================================

signal player_state_changed(save_data: PlayerSaveData)
signal scene_transition_started(from_scene: String, to_scene: String)
signal scene_transition_completed()
signal boat_changed(boat_type: String)

# ========================================
# CONSTANTS
# ========================================

# Scene paths
const PLAYER_SCENE: String = "res://scenes/player/player.tscn"
const DEFAULT_BOAT: String = "res://scenes/overworld/boats/boat.tscn"

# Save system paths
const SAVE_DIR: String = "user://saves/"
const AUTO_SAVE_FILE: String = "user://saves/autosave.tres"

# ========================================
# STATE VARIABLES
# ========================================

# Current game state
var current_save_data: PlayerSaveData = PlayerSaveData.new()
var player_instance: Player = null
var is_first_spawn: bool = true

# Scene transition tracking
var pending_transition: Dictionary = {
	"target_scene": "",
	"spawn_point": "",
	"from_scene": ""
}

# ========================================
# INITIALIZATION
# ========================================

func _ready() -> void:
	# Ensure save directory exists
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		DirAccess.make_dir_absolute(SAVE_DIR)
	
	# Load autosave if available
	load_autosave()

# ========================================
# PLAYER MANAGEMENT
# ========================================

# Spawn player in current scene at appropriate position
func spawn_player(spawn_points_parent: Node) -> Player:
	# Clean up existing player instance
	if player_instance and is_instance_valid(player_instance):
		player_instance.queue_free()
	
	# Create new player from scene
	var player_scene = load(PLAYER_SCENE) as PackedScene
	player_instance = player_scene.instantiate() as Player
	
	# Determine spawn position and rotation
	var spawn_position: Vector3
	var spawn_rotation: float
	
	if pending_transition.spawn_point != "":
		# Use specific spawn point from scene transition
		var spawn_node = spawn_points_parent.get_node_or_null(pending_transition.spawn_point)
		if spawn_node:
			spawn_position = spawn_node.global_position
			spawn_rotation = spawn_node.rotation.y
			pending_transition.spawn_point = ""  # Clear after use
		else:
			push_warning("Spawn point '%s' not found!" % pending_transition.spawn_point)
			spawn_position = current_save_data.player_position
			spawn_rotation = current_save_data.player_rotation.y
	else:
		# Use saved position from save data
		spawn_position = current_save_data.player_position
		spawn_rotation = current_save_data.player_rotation.y
	
	# Apply spawn transform
	player_instance.position = spawn_position
	player_instance.rotation.y = spawn_rotation
	
	# Mark that first spawn has occurred
	is_first_spawn = false
	
	return player_instance

# Switch player's current boat to a different type
func switch_boat(boat_scene_path: String, player: Player) -> void:
	# Validate boat scene exists
	if not ResourceLoader.exists(boat_scene_path):
		push_error("Boat scene not found: %s" % boat_scene_path)
		return
	
	var boat_scene = load(boat_scene_path) as PackedScene
	
	# Remove old boat
	if player.current_vehicle:
		player.current_vehicle.queue_free()
	
	# Create and attach new boat
	var new_boat = boat_scene.instantiate() as VehicleBase
	player.add_child(new_boat)
	
	# Update player references
	player.current_vehicle = new_boat
	player.current_vehicle.player = player
	player.detection_area = new_boat.get_detection_area()
	
	# Update save data with new boat type
	current_save_data.current_boat_type = boat_scene_path
	
	# Fix water height after spawning
	if new_boat.has_method("update_water_lock"):
		await player.get_tree().process_frame
		new_boat.update_water_lock()
	
	# Emit boat changed signal
	boat_changed.emit(boat_scene_path)

# Save current player state to memory
func save_player_state(player: Player) -> void:
	if not player:
		return
	
	# Create save data from current player state
	current_save_data = PlayerSaveData.from_player(player)
	
	# Emit state changed signal
	player_state_changed.emit(current_save_data)

# ========================================
# SCENE TRANSITIONS
# ========================================

# Prepare for scene transition (stores transition data)
func prepare_transition(target_scene: String, spawn_point: String = "") -> void:
	# Store transition parameters
	pending_transition.target_scene = target_scene
	pending_transition.spawn_point = spawn_point
	pending_transition.from_scene = get_tree().current_scene.scene_file_path
	
	# Save current player state before transition
	if player_instance:
		save_player_state(player_instance)
	
	# Emit transition started signal
	scene_transition_started.emit(pending_transition.from_scene, target_scene)

# Execute scene transition to target scene
func transition_to_scene(target_scene: String, spawn_point: String = "") -> void:
	# Prepare transition data
	prepare_transition(target_scene, spawn_point)
	
	# Change scene
	get_tree().change_scene_to_file(target_scene)

# ========================================
# SAVE/LOAD SYSTEM
# ========================================

# Save current game state to file
func save_game(save_path: String = AUTO_SAVE_FILE) -> Error:
	# Ensure player state is current
	if player_instance:
		save_player_state(player_instance)
	
	# Write save data to disk as resource
	var error = ResourceSaver.save(current_save_data, save_path)
	
	# Log result
	if error == OK:
		print("Game saved successfully to: %s" % save_path)
	else:
		push_error("Failed to save game: %s" % error)
	
	return error

# Load game state from file
func load_game(save_path: String = AUTO_SAVE_FILE) -> Error:
	# Validate save file exists
	if not FileAccess.file_exists(save_path):
		push_warning("Save file not found: %s" % save_path)
		return ERR_FILE_NOT_FOUND
	
	# Load resource from disk
	var loaded_data = ResourceLoader.load(save_path, "PlayerSaveData")
	
	# Validate loaded data
	if not loaded_data or not loaded_data is PlayerSaveData:
		push_error("Failed to load save data from: %s" % save_path)
		return ERR_FILE_CORRUPT
	
	# Apply loaded data to current state
	current_save_data = loaded_data
	print("Game loaded successfully from: %s" % save_path)
	
	return OK

# Load autosave file if it exists
func load_autosave() -> void:
	if FileAccess.file_exists(AUTO_SAVE_FILE):
		load_game(AUTO_SAVE_FILE)

# Quick save to autosave slot
func autosave() -> void:
	save_game(AUTO_SAVE_FILE)

# Delete a save file from disk
func delete_save(save_path: String) -> Error:
	if FileAccess.file_exists(save_path):
		return DirAccess.remove_absolute(save_path)
	return ERR_FILE_NOT_FOUND

# Get list of all save files in save directory
func get_save_files() -> Array[String]:
	var saves: Array[String] = []
	var dir = DirAccess.open(SAVE_DIR)
	
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		# Iterate through all files in save directory
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".tres"):
				saves.append(SAVE_DIR + file_name)
			file_name = dir.get_next()
	
	return saves

# ========================================
# HELPER FUNCTIONS
# ========================================

# Get currently equipped boat type path
func get_current_boat_type() -> String:
	return current_save_data.current_boat_type

# Set initial spawn position for first-time players
func set_initial_spawn(position: Vector3, rotation_y: float) -> void:
	if is_first_spawn:
		current_save_data.player_position = position
		current_save_data.player_rotation = Vector3(0, rotation_y, 0)

# Check if this is the first time spawning player
func is_first_time_spawn() -> bool:
	return is_first_spawn
