extends Node
class_name TitleCinematicDirector
## Title Screen Cinematic Director
## Loads the player's current overworld area into a SubViewport, strips gameplay nodes,
## picks a random AnimationPlayer cinematic clip, and cycles clips with a slow dissolve.
##
## Setup in main_menu.tscn:
##   - Add a SubViewportContainer (anchors 0,0,1,1) as the first child of MainMenu
##   - Add a SubViewport as its child, assign to @export var viewport
##   - Add a second TextureRect on top (same anchors), assign to @export var dissolve_rect
##     (this is used as the "old frame" during crossfades)
##
## Cinematic clips are AnimationPlayer animations in the overworld scene whose names
## start with the prefix defined in CINEMATIC_CLIP_PREFIX (default: "cinematic_").
## If no clips exist yet, the director just holds the camera at its default transform.

# ========================================
# CONSTANTS
# ========================================

## Prefix that identifies a cinematic animation inside an overworld scene's AnimationPlayer
const CINEMATIC_CLIP_PREFIX: String = "cinematic_"

## How long each clip plays before cycling to the next (seconds)
const CLIP_DURATION: float = 12.0

## Duration of the crossfade dissolve between clips (seconds)
const DISSOLVE_DURATION: float = 2.5

## Groups / class names of nodes to strip from the cinematic scene.
## Any node whose name contains one of these strings (case-insensitive) is hidden.
const NODES_TO_DISABLE: Array[String] = [
	"Boat", "Player", "NPC", "Dock", "Shipyard",
	"RipplingWater", "ShopDetection", "BoatTransition",
	"SceneTransitionTrigger", "RipplingWaterSpawner",
	"inventory_ui", "tutorial_ui", "dialogue_ui",
	"quests_ui", "assignment_popup_ui",
]

## Stub scene used until real per-area cinematic scenes are authored.
## Swap individual entries in AREA_SCENE_MAP to real lightweight cinematic scenes
## (NOT the full HTerrain overworld scenes) once they're built.
const CINEMATIC_STUB: String = "res://scenes/cinematics/cinematic_stub.tscn"

## Scene path used when no save file exists (the "home" area)
const HOME_SCENE: String = CINEMATIC_STUB

## Maps saved scene paths → cinematic scene paths.
## Right now every area uses the shared stub. Replace values one at a time as
## per-area cinematic scenes are authored under res://scenes/cinematics/.
const AREA_SCENE_MAP: Dictionary = {
	"res://scenes/overworld/terrain/tutorial_lake.tscn":     CINEMATIC_STUB,
	"res://scenes/overworld/terrain/lake_intersection.tscn": CINEMATIC_STUB,
	"res://scenes/overworld/terrain/fjord_area.tscn":        CINEMATIC_STUB,
	"res://scenes/overworld/terrain/delta_area.tscn":        CINEMATIC_STUB,
	"res://scenes/overworld/terrain/old_mine_area.tscn":     CINEMATIC_STUB,
	# Rhythm scenes map back to tutorial lake cinematic (player returns there)
	"res://scenes/musiclevel/rhythm_level.tscn":             CINEMATIC_STUB,
	"res://scenes/musiclevel/rhythm_level2.tscn":            CINEMATIC_STUB,
}

# ========================================
# EXPORTS
# ========================================

## The SubViewport that renders the background world
@export var viewport: SubViewport

## A TextureRect used as the "previous frame" during dissolve transitions.
## Assign a plain TextureRect with stretch mode = STRETCH_SCALE; its texture
## will be set to a ViewportTexture snapshot at the start of each dissolve.
@export var dissolve_rect: TextureRect

# ========================================
# STATE
# ========================================

var _cinematic_scene_root: Node3D = null   # The loaded overworld scene instance
var _animation_player: AnimationPlayer = null
var _available_clips: Array[String] = []
var _current_clip: String = ""
var _clip_timer: float = 0.0
var _is_dissolving: bool = false
var _ready_to_cycle: bool = false

# ========================================
# INITIALIZATION
# ========================================

func _ready() -> void:
	if not viewport:
		push_error("[TitleCinematicDirector] No SubViewport assigned!")
		return
	if not dissolve_rect:
		push_warning("[TitleCinematicDirector] No dissolve_rect assigned — crossfades disabled.")

	# Hide dissolve rect initially
	if dissolve_rect:
		dissolve_rect.modulate.a = 0.0

	# Determine which scene to load
	var target_scene := _resolve_area_scene()
	_load_cinematic_scene(target_scene)


func _process(delta: float) -> void:
	if not _ready_to_cycle or _is_dissolving:
		return

	_clip_timer -= delta
	if _clip_timer <= 0.0:
		_cycle_clip()


# ========================================
# SCENE RESOLUTION
# ========================================

## Work out which overworld scene to use as the background.
func _resolve_area_scene() -> String:
	var saved_path: String = GameStateManager.current_save_data.current_scene_path

	# No save file → home area
	if saved_path == "":
		return HOME_SCENE

	# Direct match in map
	if AREA_SCENE_MAP.has(saved_path):
		return AREA_SCENE_MAP[saved_path]

	# Fallback: if the saved scene is itself an overworld scene, use it directly
	if ResourceLoader.exists(saved_path):
		return saved_path

	return HOME_SCENE


# ========================================
# SCENE LOADING & STRIPPING
# ========================================

func _load_cinematic_scene(scene_path: String) -> void:
	if not ResourceLoader.exists(scene_path):
		push_warning("[TitleCinematicDirector] Scene not found: %s — skipping background." % scene_path)
		return

	var packed: PackedScene = load(scene_path)
	if not packed:
		push_warning("[TitleCinematicDirector] Failed to load scene: %s" % scene_path)
		return

	_cinematic_scene_root = packed.instantiate()
	viewport.add_child(_cinematic_scene_root)

	# Strip gameplay nodes so we don't run AI, physics, etc.
	_strip_gameplay_nodes(_cinematic_scene_root)

	# Locate an AnimationPlayer and build the clip list
	_animation_player = _find_animation_player(_cinematic_scene_root)
	_available_clips = _collect_cinematic_clips()

	# Start first clip
	_play_random_clip()
	_ready_to_cycle = true
	_clip_timer = CLIP_DURATION


## Recursively hide/disable any node whose name matches a gameplay keyword.
func _strip_gameplay_nodes(node: Node) -> void:
	for keyword in NODES_TO_DISABLE:
		if keyword.to_lower() in node.name.to_lower():
			if node is Node3D:
				(node as Node3D).visible = false
			if node is CollisionObject3D:
				(node as CollisionObject3D).collision_layer = 0
				(node as CollisionObject3D).collision_mask = 0
			if node is Area3D:
				(node as Area3D).monitoring = false
				(node as Area3D).monitorable = false
			# Don't recurse into stripped nodes
			return

	for child in node.get_children():
		_strip_gameplay_nodes(child)


## Depth-first search for the first AnimationPlayer in the scene.
func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for child in node.get_children():
		var result := _find_animation_player(child)
		if result:
			return result
	return null


## Collect all animation names that start with CINEMATIC_CLIP_PREFIX.
func _collect_cinematic_clips() -> Array[String]:
	var clips: Array[String] = []
	if not _animation_player:
		return clips
	for anim_name in _animation_player.get_animation_list():
		if anim_name.begins_with(CINEMATIC_CLIP_PREFIX):
			clips.append(anim_name)
	return clips


# ========================================
# CLIP PLAYBACK
# ========================================

## Play a random clip, avoiding repeating the current one if possible.
func _play_random_clip() -> void:
	if _available_clips.is_empty():
		# No cinematic clips authored yet — just leave the scene static.
		return

	var candidates := _available_clips.duplicate()
	if candidates.size() > 1:
		candidates.erase(_current_clip)

	_current_clip = candidates[randi() % candidates.size()]
	_animation_player.play(_current_clip)


## Crossfade to the next clip using a slow dissolve.
func _cycle_clip() -> void:
	if _available_clips.size() <= 1 or not dissolve_rect:
		# No dissolve possible — just cut
		_play_random_clip()
		_clip_timer = CLIP_DURATION
		return

	_is_dissolving = true

	# Snapshot the current viewport frame into the dissolve rect
	await get_tree().process_frame  # Ensure frame is rendered
	var img := viewport.get_texture().get_image()
	var snapshot := ImageTexture.create_from_image(img)
	dissolve_rect.texture = snapshot
	dissolve_rect.modulate.a = 1.0

	# Switch to the new clip (hidden behind the snapshot)
	_play_random_clip()

	# Fade the snapshot out → reveals the new clip underneath
	var tween := create_tween()
	tween.tween_property(dissolve_rect, "modulate:a", 0.0, DISSOLVE_DURATION).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	await tween.finished

	_is_dissolving = false
	_clip_timer = CLIP_DURATION


# ========================================
# CLEANUP
# ========================================

## Call this before transitioning away from the title screen to free the heavy scene.
func cleanup() -> void:
	_ready_to_cycle = false
	if _cinematic_scene_root and is_instance_valid(_cinematic_scene_root):
		_cinematic_scene_root.queue_free()
		_cinematic_scene_root = null
