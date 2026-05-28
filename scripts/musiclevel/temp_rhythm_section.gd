extends Node3D
## Controls the rhythm fishing minigame level flow.
## Author: Tyler Schauermann
## Date of last update: 05/24/2026

const COUNTDOWN_SCENE = preload("res://scenes/ui/transitions/rhythm_countdown.tscn")

@export var referee: Referee
@export var judge: RhythmJudge

## The unique fish ID this rhythm level rewards on a successful catch.
## Must exactly match a fish_id entry in FishRegistry's FISH_DATA.
@export var fish_id: String = ""

var _countdown_instance: RhythmCountdown = null
var _level_ended: bool = false
var _caught_successfully: bool = false  # true only when the player wins (rarity != "")

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

func _unhandled_input(event: InputEvent) -> void:
	if _level_ended:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_W:
			_on_fishing_finished(1.0, "legendary")
		elif event.keycode == KEY_E:
			_on_fishing_finished(0.0, "")

func _on_fishing_finished(_performance: float, rarity: String) -> void:
	if _level_ended:
		return

	_level_ended = true

	if rarity != "":
		if fish_id != "":
			InventoryManager.add_fish(fish_id)
			_caught_successfully = true
		else:
			push_warning("[TempRhythmSection] fish_id not set — fish won't be recorded.")
		# Quest progress is checked automatically when the player talks to an NPC.
		# No manual update_progress() call needed.

	_return_to_overworld()

func _return_to_overworld() -> void:
	set_process(false)
	referee.set_process(false)
	call_deferred("_safety_check")

func _safety_check() -> void:
	var overworld_music = get_node_or_null("/root/OverworldMusic")

	# ── Final boss win → end credits ────────────────────────────────────
	if fish_id == "final_boss" and _caught_successfully:
		if overworld_music:
			overworld_music.on_exit_rhythm_level()
		ScreenTransition.transition_to_scene("res://scenes/credits/end_credits.tscn")
		return

	# ── All other levels → return to overworld ───────────────────────────
	var return_scene: String
	if GameStateManager.pending_transition.from_scene != "":
		return_scene = GameStateManager.pending_transition.from_scene
	else:
		return_scene = "res://scenes/overworld/terrain/tutorial_lake.tscn"

	if overworld_music:
		overworld_music.on_exit_rhythm_level()

	ScreenTransition.transition_to_scene(return_scene)
