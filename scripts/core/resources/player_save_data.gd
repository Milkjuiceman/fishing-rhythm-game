extends Resource
class_name PlayerSaveData
## Player Save Data Resource
## Stores all persistent player data for save/load functionality
## Designed for easy expansion - add new @export variables as game features grow

# ========================================
# PLAYER STATE
# ========================================

# Position and orientation
@export var player_position: Vector3 = Vector3.ZERO
@export var player_rotation: Vector3 = Vector3.ZERO

# ========================================
# VEHICLE STATE
# ========================================

# Current boat scene path
@export var current_boat_type: String = "res://scenes/overworld/boats/boat.tscn"

# ========================================
# SCENE TRANSITION DATA
# ========================================

# Current level the player is in
@export var current_scene_path: String = ""

# Target spawn point for scene transitions
@export var target_spawn_point: String = ""

# ========================================
# METADATA
# ========================================

# Timestamp of last save
@export var last_saved: String = ""

# Save file version for future migration support
@export var save_version: int = 1

# inventory data
@export var inventory: Inventory = Inventory.new()

# ========================================
# FUTURE EXPANSION (Commented Examples)
# ========================================

# Add these as your game grows:
# @export var quest_flags: Dictionary = {}
# @export var stats: Dictionary = {}
# @export var unlocked_boats: Array[String] = []
# @export var currency: int = 0
# @export var fish_caught: Dictionary = {}

# ========================================
# INITIALIZATION
# ========================================

# Create new save data with optional initial values
func _init(
	p_position: Vector3 = Vector3.ZERO,
	p_rotation: Vector3 = Vector3.ZERO,
	p_boat_type: String = "res://scenes/overworld/boats/boat.tscn"
):
	player_position = p_position
	player_rotation = p_rotation
	current_boat_type = p_boat_type
	last_saved = Time.get_datetime_string_from_system()

# ========================================
# FACTORY METHODS
# ========================================

# Create save data from current player state
static func from_player(player: Player) -> PlayerSaveData:
	var save_data = PlayerSaveData.new()
	# Capture player position and rotation
	save_data.player_position = player.get_current_position()
	save_data.player_rotation = player.get_current_rotation()
	# Capture current boat type
	if player.current_vehicle and player.current_vehicle.scene_file_path:
		save_data.current_boat_type = player.current_vehicle.scene_file_path
	# Capture current scene
	save_data.current_scene_path = player.get_tree().current_scene.scene_file_path
	# Update timestamp
	save_data.last_saved = Time.get_datetime_string_from_system()
	return save_data

# ========================================
# APPLICATION METHODS
# ========================================

# Apply saved data to player instance
func apply_to_player(player: Player) -> void:
	# Restore position and rotation
	player.global_position = player_position
	player.rotation = player_rotation
	
	# Note: Boat switching handled separately by GameStateManager
