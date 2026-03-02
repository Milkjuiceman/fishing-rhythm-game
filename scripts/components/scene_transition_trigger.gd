extends Area3D
class_name SceneTransitionTrigger
## Scene Transition Trigger Component
## Generic, reusable component for all scene transitions - eliminates duplicate code
## Configure via Inspector - no scripting required per transition
## Automatically saves player state and handles scene changes via GameStateManager
## Uses ScreenTransition for smooth white fade effect

# ========================================
# CONFIGURATION
# ========================================

# Target scene to transition to (set via Inspector)
@export_file("*.tscn") var target_scene_path: String = ""

# Spawn point name in target scene (set via Inspector)
@export var target_spawn_point: String = ""

# If true, only triggers for boats; if false, triggers for any body
@export var trigger_on_boat_only: bool = true

# Transition settings
@export_group("Transition Settings")
@export var use_screen_transition: bool = true
@export var fade_out_duration: float = 0.4
@export var fade_in_duration: float = 0.6

# Prevent double-triggering
var _is_transitioning: bool = false

# ========================================
# INITIALIZATION
# ========================================

func _ready() -> void:
	# Connect collision detection
	body_entered.connect(_on_body_entered)

# ========================================
# COLLISION DETECTION
# ========================================

# Triggered when a body enters the transition area
func _on_body_entered(body: Node3D) -> void:
	# Prevent double-triggering
	if _is_transitioning:
		return
	
	# Filter by body type if configured
	if trigger_on_boat_only and not body is Boat:
		return
	
	# Validate scene path is configured
	if target_scene_path == "":
		push_error("SceneTransitionTrigger: No target scene set!")
		return
	
	# Validate target scene exists
	if not ResourceLoader.exists(target_scene_path):
		push_error("SceneTransitionTrigger: Target scene not found: %s" % target_scene_path)
		return
	
	# Extract player and boat references from triggering body
	var player: Player = null
	var boat: Boat = null
	
	if body is Boat:
		boat = body
		player = body.player
	elif body is Player:
		player = body
		if player.current_vehicle is Boat:
			boat = player.current_vehicle
	
	# Ensure player reference is valid
	if not player:
		push_warning("SceneTransitionTrigger: Could not find player reference")
		return
	
	# Execute scene transition
	_trigger_transition(player, boat)

# ========================================
# SCENE TRANSITION
# ========================================

# Save player state and transition to target scene
func _trigger_transition(player: Player, boat: Boat) -> void:
	_is_transitioning = true
	
	# Stop boat engine sounds before transition
	if boat and boat.has_method("stop_engine_sounds"):
		boat.stop_engine_sounds()
	
	# Save current player state for persistence
	GameStateManager.save_player_state(player)
	
	# Prepare transition data in GameStateManager
	GameStateManager.prepare_transition(target_scene_path, target_spawn_point)
	
	# Use ScreenTransition if available, otherwise fall back to direct change
	var screen_transition = get_node_or_null("/root/ScreenTransition")
	if use_screen_transition and screen_transition:
		screen_transition.transition_to_scene(target_scene_path, fade_out_duration, fade_in_duration)
	else:
		# Fallback to direct scene change
		get_tree().change_scene_to_file(target_scene_path)