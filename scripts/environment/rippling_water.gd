extends Area3D
class_name RipplingWater
## Rippling Water Trigger
## Detects boat collisions and transitions to rhythm minigame fishing sequence
## Uses GameStateManager for proper scene transitions and return handling

# ========================================
# CONSTANTS
# ========================================

const DEFAULT_RHYTHM_SCENE_PATH: String = "res://scenes/musiclevel/rhythm_level.tscn"

# ========================================
# CONFIGURATION
# ========================================

@export_range(-100.0, 100.0) var lake_min_x: float = 0.0
@export_range(-100.0, 100.0) var lake_max_x: float = 150.0
@export_range(-100.0, 100.0) var lake_min_z: float = 0.0
@export_range(-100.0, 100.0) var lake_max_z: float = 150.0

@export var water_height: float = 0.0
@export_range(0.1, 10.0) var respawn_delay: float = 2.0

# ========================================
# RUNTIME STATE
# ========================================

## Set by RipplingWaterSpawner before this node enters the tree.
## Determines which rhythm level this water spot leads to.
var _assigned_level: RhythmLevelEntry = null

# ========================================
# INITIALIZATION
# ========================================

func _ready() -> void:
	body_entered.connect(_on_body_entered)

# ========================================
# PUBLIC API (called by RipplingWaterSpawner)
# ========================================

## Called by the spawner before the node enters the scene tree.
func set_rhythm_level(entry: RhythmLevelEntry) -> void:
	_assigned_level = entry

# ========================================
# COLLISION DETECTION
# ========================================

func _on_body_entered(body: Node3D) -> void:
	if not body is Boat:
		return

	var player = body.player
	if not player:
		return

	_start_rhythm_minigame(player)

# ========================================
# MINIGAME TRANSITION
# ========================================

func _start_rhythm_minigame(player: Player) -> void:
	print("Starting rhythm minigame...")

	# Use the assigned level's scene, or fall back to the default
	var target_scene: String
	if _assigned_level != null and _assigned_level.scene_path != "":
		target_scene = _assigned_level.scene_path
	else:
		push_warning("[RipplingWater] No rhythm level assigned — using default scene.")
		target_scene = DEFAULT_RHYTHM_SCENE_PATH

	if not ResourceLoader.exists(target_scene):
		push_error("[RipplingWater] Rhythm scene not found: %s" % target_scene)
		return

	GameStateManager.save_player_state(player)
	GameStateManager.prepare_transition(target_scene, "")

	var overworld_music = get_node_or_null("/root/OverworldMusic")
	if overworld_music:
		overworld_music.on_enter_rhythm_level()

	var screen_transition = get_node_or_null("/root/ScreenTransition")
	if screen_transition:
		screen_transition.transition_to_scene(target_scene)
	else:
		call_deferred("_change_scene_to", target_scene)

func _change_scene_to(scene_path: String) -> void:
	get_tree().change_scene_to_file(scene_path)

# ========================================
# RESPAWN SYSTEM
# ========================================

func respawn_at_random_location() -> void:
	if not is_inside_tree():
		return

	visible = false
	monitoring = false
	monitorable = false

	await get_tree().create_timer(respawn_delay).timeout

	if not is_inside_tree():
		return

	var random_x: float = randf_range(lake_min_x, lake_max_x)
	var random_z: float = randf_range(lake_min_z, lake_max_z)

	global_position = Vector3(random_x, water_height, random_z)

	visible = true
	monitoring = true
	monitorable = true
