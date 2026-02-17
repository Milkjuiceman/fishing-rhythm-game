extends Area3D
class_name RipplingWater
## Rippling Water Trigger
## Detects boat collisions and transitions to rhythm minigame fishing sequence
## Uses GameStateManager for proper scene transitions and return handling

# ========================================
# CONSTANTS
# ========================================

const RHYTHM_SCENE_PATH: String = "res://scenes/musiclevel/rhythm_level.tscn"

# ========================================
# CONFIGURATION
# ========================================

# Lake boundaries for random respawn positioning
@export_range(-100.0, 100.0) var lake_min_x: float = 0.0
@export_range(-100.0, 100.0) var lake_max_x: float = 150.0
@export_range(-100.0, 100.0) var lake_min_z: float = 0.0
@export_range(-100.0, 100.0) var lake_max_z: float = 150.0

# Spawn positioning
@export var water_height: float = 0.0  # Y position for water surface

# Respawn timing
@export_range(0.1, 10.0) var respawn_delay: float = 2.0  # Delay before respawning

# ========================================
# INITIALIZATION
# ========================================

func _ready() -> void:
	# Connect collision detection
	body_entered.connect(_on_body_entered)

# ========================================
# COLLISION DETECTION
# ========================================

# Triggered when a body enters the water area
func _on_body_entered(body: Node3D) -> void:
	# Only respond to boat collisions
	if not body is Boat:
		return
	
	# Get player reference from boat
	var player = body.player
	if not player:
		return
	
	# Start fishing minigame
	_start_rhythm_minigame(player)

# ========================================
# MINIGAME TRANSITION
# ========================================

# Initiate transition to rhythm minigame
func _start_rhythm_minigame(player: Player) -> void:
	print("Starting rhythm minigame...")
	
	# Validate minigame scene exists
	if not ResourceLoader.exists(RHYTHM_SCENE_PATH):
		push_error("Rhythm scene not found: %s" % RHYTHM_SCENE_PATH)
		return
	
	# Save current player state for return
	GameStateManager.save_player_state(player)
	
	# Prepare transition (stores current scene for return navigation)
	GameStateManager.prepare_transition(RHYTHM_SCENE_PATH)
	
	# Execute scene change (deferred to avoid physics conflicts)
	call_deferred("_change_scene")

# Change to rhythm minigame scene
func _change_scene() -> void:
	get_tree().change_scene_to_file(RHYTHM_SCENE_PATH)

# ========================================
# RESPAWN SYSTEM
# ========================================

# Relocate water to random position within lake boundaries
func respawn_at_random_location() -> void:
	# Ensure still in scene tree
	if not is_inside_tree():
		return
	
	# Hide and disable while repositioning
	visible = false
	monitoring = false
	monitorable = false
	
	# Wait for respawn delay
	await get_tree().create_timer(respawn_delay).timeout
	
	# Verify still in tree after delay
	if not is_inside_tree():
		return
	
	# Calculate random position within lake bounds
	var random_x: float = randf_range(lake_min_x, lake_max_x)
	var random_z: float = randf_range(lake_min_z, lake_max_z)
	
	# Apply new position
	global_position = Vector3(random_x, water_height, random_z)
	
	# Re-enable visibility and collision
	visible = true
	monitoring = true
	monitorable = true
