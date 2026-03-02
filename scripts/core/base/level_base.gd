extends Node3D
class_name LevelBase
## Level Base Class
## Abstract base class for all game levels with automatic player spawning and boat management
## Extend this class instead of duplicating spawn logic in every level
## Provides lifecycle hooks for level-specific setup before and after player spawn

# ========================================
# CONFIGURATION
# ========================================

# Override in child classes if spawn points container has different name
@export var spawn_points_node_path: NodePath = "SpawnPoints"

# Override in child classes to match scene's initial spawn point name
@export var initial_spawn_point_name: String = "initial_spawnpoint"

# ========================================
# REFERENCES
# ========================================

var player: Player = null  # Spawned player instance

@onready var spawn_points: Node = get_node_or_null(spawn_points_node_path)

# ========================================
# INITIALIZATION
# ========================================

func _ready() -> void:
	# Execute level lifecycle in order
	_setup_level()      # Pre-spawn setup
	_spawn_player()     # Spawn and configure player
	_post_spawn_setup() # Post-spawn setup
	_start_boat_audio() # Start boat sounds after everything is ready

# ========================================
# LIFECYCLE HOOKS (Override in Child Classes)
# ========================================

# Setup level state before player spawns (override in child classes)
func _setup_level() -> void:
	pass

# Setup level state after player has spawned (override in child classes)
func _post_spawn_setup() -> void:
	pass

# ========================================
# PLAYER SPAWNING
# ========================================

# Spawn player using GameStateManager with saved or initial position
func _spawn_player() -> void:
	# Validate spawn points container exists
	if not spawn_points:
		push_error("Spawn points node not found at path: %s" % spawn_points_node_path)
		return
	
	# Configure initial spawn point for first-time players
	if GameStateManager.is_first_time_spawn():
		_setup_initial_spawn()
	
	# Spawn player via GameStateManager (handles saved position)
	player = GameStateManager.spawn_player(spawn_points)
	add_child(player)
	
	# Restore saved boat type if different from current
	var saved_boat = GameStateManager.get_current_boat_type()
	if player.current_vehicle and player.current_vehicle.scene_file_path != saved_boat:
		await get_tree().process_frame
		GameStateManager.switch_boat(saved_boat, player)

# Configure initial spawn point for first-time players
func _setup_initial_spawn() -> void:
	var initial_spawn = spawn_points.get_node_or_null(initial_spawn_point_name)
	
	if initial_spawn:
		# Store initial spawn position in GameStateManager
		GameStateManager.set_initial_spawn(
			initial_spawn.global_position,
			initial_spawn.rotation.y
		)
	else:
		push_warning("Initial spawn point '%s' not found!" % initial_spawn_point_name)

# ========================================
# AUDIO MANAGEMENT
# ========================================

# Start boat engine sounds after player is fully spawned
func _start_boat_audio() -> void:
	# Wait a frame to ensure everything is initialized
	await get_tree().process_frame
	
	if not player:
		return
	
	# Get the boat from the player
	var boat = player.current_vehicle
	if boat and boat is Boat and boat.has_method("start_engine_sounds"):
		# Check if boat SFX exists and engine isn't already running
		var boat_sfx = boat.get_node_or_null("BoatSFX")
		if boat_sfx and boat_sfx.has_method("is_engine_running"):
			if not boat_sfx.is_engine_running():
				boat.start_engine_sounds()
		elif boat_sfx:
			# BoatSFX exists but might auto-start, so don't double-start
			pass
		else:
			# No BoatSFX node, nothing to start
			pass

# ========================================
# LEVEL EXIT
# ========================================

# Save player state when leaving level (call before scene transitions)
func _on_level_exit() -> void:
	if player:
		GameStateManager.save_player_state(player)
	
	# Auto-save on level exit
	GameStateManager.autosave()
