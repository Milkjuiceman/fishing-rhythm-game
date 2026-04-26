extends Node3D
## Controls the rhythm fishing minigame level flow.
## Author: Tyler Schauermann
## Date of last update: 04/22/2026

# ========================================
# CONSTANTS AND EXPORTED VARIABLES
# ========================================

const COUNTDOWN_SCENE = preload("res://scenes/ui/transitions/rhythm_countdown.tscn")

@export var referee: Referee
@export var judge: RhythmJudge

## The quest ID to mark progress on when a fish is caught.
@export var quest_id: String = "tutorial_01"

## The unique fish ID this rhythm level rewards on a successful catch.
## Must exactly match a fish_id entry in FishRegistry's FISH_DATA.
@export var fish_id: String = ""

# ========================================
# RUNTIME STATE
# ========================================

var _countdown_instance: RhythmCountdown = null
var _level_ended: bool = false

# ========================================
# STARTUP AND COUNTDOWN
# ========================================

func _ready() -> void:
	_show_countdown()
	referee.fish_caught.connect(_on_fishing_finished)

func _show_countdown() -> void:
	_countdown_instance = COUNTDOWN_SCENE.instantiate()
	add_child(_countdown_instance)
	_countdown_instance.countdown_finished.connect(_on_countdown_finished)
	_countdown_instance.start_countdown()

func _on_countdown_finished() -> void:
	referee.play_chart_now.emit(referee.chart)

# ========================================
# DEBUG KEYS
# ========================================

func _unhandled_input(event: InputEvent) -> void:
	if _level_ended:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_W:
			_on_fishing_finished(1.0, "legendary")
		elif event.keycode == KEY_E:
			_on_fishing_finished(0.0, "")

# ========================================
# FISHING RESULTS
# ========================================

func _on_fishing_finished(performance: float, rarity: String) -> void:
	if _level_ended:
		return
	_level_ended = true

	# rarity == "" means fail — skip all rewards
	if rarity != "":
		if fish_id != "":
			InventoryManager.add_fish(fish_id)
		else:
			push_warning("[TempRhythmSection] fish_id not set — fish won't be recorded.")
		if quest_id != "":
			QuestManager.update_progress(quest_id, 1)

	_return_to_overworld()

# ========================================
# LEVEL EXIT
# ========================================

func _return_to_overworld() -> void:
	set_process(false)
	referee.set_process(false)
	call_deferred("_safety_check")

func _safety_check() -> void:
	var return_scene: String
	if GameStateManager.pending_transition.from_scene != "":
		return_scene = GameStateManager.pending_transition.from_scene
	else:
		return_scene = "res://scenes/overworld/terrain/tutorial_lake.tscn"

	# Fade overworld music back in on return
	var overworld_music = get_node_or_null("/root/OverworldMusic")
	if overworld_music:
		overworld_music.on_exit_rhythm_level()

	ScreenTransition.transition_to_scene(return_scene)
