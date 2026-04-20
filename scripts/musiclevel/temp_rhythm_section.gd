extends Node3D 
## Controls the rhythm fishing minigame level flow including countdown initialization and gameplay start.
## Acts as a controller between the UI countdown system, the Referee rhythm gameplay logic, 
## and the GameStateManager for inventory updates and scene transitions.
## Author: Tyler Schauermann
## Date of last update: 03/09/2026

# ========================================
# CONSTANTS AND EXPORTED VARIABLES
# ========================================

const COUNTDOWN_SCENE = preload("res://scenes/ui/transitions/rhythm_countdown.tscn")

@export var referee: Referee
@export var judge: RhythmJudge

## The quest ID to mark progress on when a fish is caught.
## Set this in the Inspector to match the active quest (e.g. "tutorial_01").
@export var quest_id: String = "tutorial_01"

# ========================================
# RUNTIME STATE VARIABLES
# ========================================

var _countdown_instance: RhythmCountdown = null
var _level_ended: bool = false

# ========================================
# STARTUP AND COUNTDOWN
# ========================================

func _ready() -> void:
	_show_countdown()
	referee.fish_caught.connect(_on_fishing_finished)
	referee.fish_failed.connect(_on_fishing_failed)

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
			_level_ended = true
			_on_fishing_finished(1.0, "legendary")
		elif event.keycode == KEY_E:
			_level_ended = true
			_on_fishing_failed()

# ========================================
# FISHING RESULTS
# ========================================

func _on_fishing_finished(performance: float, rarity: String) -> void:
	if _level_ended and not (performance == 1.0 and rarity == "legendary"):
		return
	_level_ended = true

	if quest_id != "":
		QuestManager.update_progress(quest_id, 1)

	_return_to_overworld()

func _on_fishing_failed() -> void:
	if _level_ended:
		return
	_level_ended = true
	_return_to_overworld()

func _determine_rarity(ratio: float) -> String:
	if ratio > 0.9:
		return "legendary"
	elif ratio > 0.7:
		return "rare"
	elif ratio > 0.4:
		return "uncommon"
	else:
		return "common"

# ========================================
# LEVEL EXIT / SCENE TRANSITION
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

	ScreenTransition.transition_to_scene(return_scene)
