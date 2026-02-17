extends Area3D
class_name SceneTransitionTrigger
## Scene Transition Trigger Component
## Generic, reusable component for all scene transitions - eliminates duplicate code
## Configure via Inspector - no scripting required per transition
## Automatically saves player state and handles scene changes via GameStateManager

# ========================================
# CONFIGURATION
# ========================================

# Target scene to transition to (set via Inspector)
@export_file("*.tscn") var target_scene_path: String = ""

# Spawn point name in target scene (set via Inspector)
@export var target_spawn_point: String = ""

# If true, only triggers for boats; if false, triggers for any body
@export var trigger_on_boat_only: bool = true

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
	
	# Extract player reference from triggering body
	var player: Player = null
	if body is Boat:
		player = body.player
	elif body is Player:
		player = body
	
	# Ensure player reference is valid
	if not player:
		push_warning("SceneTransitionTrigger: Could not find player reference")
		return
	
	# Execute scene transition
	_trigger_transition(player)

# ========================================
# SCENE TRANSITION
# ========================================

# Save player state and transition to target scene
func _trigger_transition(player: Player) -> void:
	# Save current player state for persistence
	GameStateManager.save_player_state(player)
	
	# Execute scene transition via GameStateManager
	GameStateManager.transition_to_scene(target_scene_path, target_spawn_point)
