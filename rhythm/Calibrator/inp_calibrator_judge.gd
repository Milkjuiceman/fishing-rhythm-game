extends Node

signal calibration_finished(offset_sec: float)

const NOTE_SPACING := 1.0        # seconds between notes
const FIRST_NOTE := 1.0          # first note at 1 second
const HIT_WINDOW := 1
const REQUIRED_HITS := 10

var logic_time := 0.0
var note_index := 0
var hits := 0
var offsets_ms := []
var finished := false

func _process(delta: float) -> void:
	if finished:
		return

	logic_time += delta

	var hit_time := get_current_hit_time()

	# Missed note → advance
	if logic_time > hit_time + HIT_WINDOW:
		note_index += 1

func _input(event) -> void:
	if finished:
		return

	if Input.is_action_just_pressed(&"calibration"):
		var hit_time := get_current_hit_time()
		var offset := logic_time - hit_time

		if abs(offset) <= HIT_WINDOW:
			offsets_ms.append(offset)
			hits += 1
			note_index += 1

			if hits >= REQUIRED_HITS:
				finish_calibration()

func get_current_hit_time() -> float:
	return FIRST_NOTE + note_index * NOTE_SPACING

func finish_calibration() -> void:
	finished = true

	offsets_ms.sort()
	var median : float
	median = offsets_ms[offsets_ms.size() / 2]

	print("Input Offset:", median, "ms")
	
	emit_signal("calibration_finished", median)
	
	_return_to_previous_scene()
	
	
func _return_to_previous_scene() -> void:
	await get_tree().create_timer(2.0).timeout
	print("[Judge] _return_to_previous_scene called")
	var return_scene = _get_return_scene()
	print("[Judge] Returning to: ", return_scene)

	var overworld_music = get_node_or_null("/root/OverworldMusic")
	if overworld_music:
		overworld_music.on_exit_rhythm_level()

	ScreenTransition.transition_to_scene(return_scene)


func _get_return_scene() -> String:
	if not has_node("/root/GameStateManager"):
		push_warning("[Judge] GameStateManager not found - using fallback")
		return "res://scenes/overworld/terrain/tutorial_lake.tscn"

	var gsm = get_node("/root/GameStateManager")

	if gsm.pending_transition.has("from_scene") and gsm.pending_transition.from_scene != "":
		return gsm.pending_transition.from_scene

	if gsm.current_save_data.current_scene_path != "":
		return gsm.current_save_data.current_scene_path

	push_warning("[Judge] No return scene found - using tutorial lake")
	return "res://scenes/overworld/terrain/tutorial_lake.tscn"
