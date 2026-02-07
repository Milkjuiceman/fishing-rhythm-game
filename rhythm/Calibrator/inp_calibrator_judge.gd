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
	
	get_tree().paused = true
