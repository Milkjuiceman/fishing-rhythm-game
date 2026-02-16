extends Area3D

# Path to the rhythm minigame scene
const RHYTHM_SCENE_PATH: String = "res://scenes/musiclevel/rhythm_level.tscn"

@export_range(-100.0, 100.0) var lake_min_x: float = 0.0
@export_range(-100.0, 100.0) var lake_max_x: float = 150.0
@export_range(-100.0, 100.0) var lake_min_z: float = 0.0
@export_range(-100.0, 100.0) var lake_max_z: float = 150.0
@export var water_height: float = 0.0
@export_range(0.1, 10.0) var respawn_delay: float = 2.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)

# Called when the rigid body enters the area
func _on_body_entered(body: Node3D) -> void:
	# Check if it's a boat 
	if body is Boat:
		# Get the player 
		var player = body.player
		if player:
			_load_rhythm_scene(player)

# Loads the rhythm minigame scene and saves player state
func _load_rhythm_scene(player: Player) -> void:
	print("Attempting to load rhythm scene...")
	
	# Check if the scene file exists
	if not ResourceLoader.exists(RHYTHM_SCENE_PATH):
		push_error("Scene file not found at: " + RHYTHM_SCENE_PATH)
		return
	
	print("Scene found! Saving player state and changing scene...")
	
	# Save the player's state (position, rotation, current boat type)
	BoatManager.save_player_state(player)
	
	# Save which scene we're coming from so we can return to it
	var current_scene_path = get_tree().current_scene.scene_file_path
	BoatManager.return_scene_path = current_scene_path
	# DON'T call set_transition - that would reset target_spawn_point
	# We want target_spawn_point to stay empty so it uses saved position
	
	# Defer the scene change to avoid issues with physics processing
	call_deferred("_change_scene")

func _change_scene() -> void:
	if get_tree():
		get_tree().change_scene_to_file(RHYTHM_SCENE_PATH)
	else:
		push_error("SceneTree is null!")

# Spawns water at a random location within specified coordinates
func _respawn_at_random_location() -> void:
	# Check if we're still in the scene tree
	if not is_inside_tree():
		return
	
	visible = false
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	
	await get_tree().create_timer(respawn_delay).timeout
	
	# Check again after the delay 
	if not is_inside_tree():
		return
	
	var random_x: float = randf_range(lake_min_x, lake_max_x)
	var random_z: float = randf_range(lake_min_z, lake_max_z)
	
	global_position = Vector3(random_x, water_height, random_z)
	
	visible = true
	set_deferred("monitoring", true)
	set_deferred("monitorable", true)
