@tool
extends Node

@export var chart: Resource:
	set(value):
		if chart == value: return
		chart = value
		if chart == GameStateManager.current_selected_chart:
			if Engine.is_editor_hint():
				return
			print("[Snapper] Chart updated to: ", chart.resource_path.get_file())

var current_note: float = 0.0

# exported buttons: define callables directly here
@export_tool_button("Generate next beat") var generate_full_beat = func(): generate_next_beat(WHOLE)
@export_tool_button("Skip a beat") var skip_beat = func(): generate_next_beat(DOUBLE)
@export_tool_button("Generate next 1/3 beat") var generate_triplet_beat = func(): generate_next_beat(TRIPLET)
@export_tool_button("Generate next 2/3 beat") var generate_2_triplet_beat = func(): generate_next_beat(DOUBLE_TRIPLET)
@export_tool_button("Generate next 1/8 beat") var generate_eighth_beat = func(): generate_next_beat(EIGHTH)
@export_tool_button("Generate next 1/4 beat") var generate_quarter_beat = func(): generate_next_beat(QUARTER)
@export_tool_button("Generate next 1/2 beat") var generate_half_beat = func(): generate_next_beat(HALF)
@export_tool_button("Snap Entire Chart") var snap_button = func(): snap_to_grid()

# CSV buttons
@export_tool_button("Export to CSV") var export_button := Callable(self, &"export_to_csv")
@export_tool_button("Import from CSV") var import_button := Callable(self, &"import_from_csv")

func get_active_bpm() -> float:
	if not chart or not chart.track or not chart.track.bpm:
		return 120.0
	var bpm_dict = chart.track.bpm
	return bpm_dict.get(0.0, bpm_dict.values()[0])

func export_to_csv() -> void:
	if not chart:
		push_error("No chart resource assigned!")
		return

	var file = FileAccess.open("res://chart_debug.csv", FileAccess.WRITE)
	if not file:
		push_error("Could not create CSV file!")
		return

	file.store_line("time,column")
	for i in range(chart.note_timings.size()):
		file.store_line(str(chart.note_timings[i]) + "," + str(chart.note_column[i]))

	print("Successfully exported %d notes to res://chart_debug.csv" % chart.note_timings.size())

func import_from_csv() -> void:
	if not chart:
		push_error("No chart resource assigned!")
		return

	if not FileAccess.file_exists("res://chart_debug.csv"):
		push_error("CSV file not found at res://chart_debug.csv")
		return

	var file = FileAccess.open("res://chart_debug.csv", FileAccess.READ)
	file.get_line() # Skip header

	var new_times := PackedFloat64Array()
	var new_cols := PackedInt64Array()
	while !file.eof_reached():
		var line_text = file.get_line()

		if line_text == "":
			continue

		var parts = line_text.split(",")

		if parts.size() < 2:
			continue

		var t_str = parts[0].strip_edges()
		var c_str = parts[1].strip_edges()

		# skip header safely
		if t_str == "time":
			continue

		var t = t_str.to_float()
		var c = c_str.to_int()

		# CRITICAL: reject only obviously bad rows
		# (this is what prevents your 0.0 spam)
		if t == 0.0 and t_str != "0" and t_str != "0.0":
			continue

		new_times.append(t)
		new_cols.append(c)

	chart.note_timings = new_times
	chart.note_column = new_cols
	_finalize_chart("imported from csv")
	print("Successfully imported %d notes." % new_times.size())

# Subdivision constants
const WHOLE = 1.0
const DOUBLE = 2.0
const TRIPLET = 1.0/3.0
const DOUBLE_TRIPLET = 2.0/3.0
const EIGHTH = 1.0/8.0
const QUARTER = 0.25
const HALF = 0.5

func _ready():
	if not Engine.is_editor_hint():
		var sender = get_parent().get_node("Judge")
		sender.send_key_times.connect(_on_receive_key_times)
		
func _get_property_list():
	# only use this to add non button dynamic properties
	return []
	
# input merge pipeline
func _on_receive_key_times(key_times: PackedFloat64Array, key_columns: PackedInt64Array, start: float, finish: float) -> void:
	var judge = get_parent().get_node("Judge")
	
	if judge.testing:
		_print_test_results(judge.scorecard)
		get_tree().quit()
		return
		
	var bpm: float = chart.track.bpm[0.0]
	var beat_length = 60.0 / bpm
	
	# snap incoming inputs
	for i in range(key_times.size()):
		key_times[i] = get_best_snap(key_times[i], beat_length)

	var merged_times := PackedFloat64Array()
	var merged_columns := PackedInt64Array()

	# keep notes outside edit window
	for i in range(chart.note_timings.size()):
		var t = chart.note_timings[i]
		if t < start or t > finish:
			merged_times.append(t)
			merged_columns.append(chart.note_column[i])

	# add new snapped notes
	for i in range(key_times.size()):
		merged_times.append(key_times[i])
		merged_columns.append(key_columns[i])

	# sort while keeping columns aligned
	sort_notes(merged_times, merged_columns)

	# apply
	chart.note_timings = merged_times
	chart.note_column = merged_columns
	_finalize_chart("snapped + merged notes")
	print("should be saved now, closing")
	get_tree().quit()

func snap_to_grid() -> void:
	if chart.note_timings.is_empty():
		push_warning("No notes to snap!")
		return
	var bpm: float = chart.track.bpm[0.0]
	var beat_length = 60.0 / bpm
	for i in range(chart.note_timings.size()):
		chart.note_timings[i] = get_best_snap(chart.note_timings[i], beat_length)
	sort_notes(chart.note_timings, chart.note_column)
	_finalize_chart("grid snapped")
	
func get_best_snap(t: float, beat_length: float) -> float:
	var subdivisions := get_active_subdivisions()

	var best_snap = t
	var smallest_diff = INF

	for s in subdivisions:
		var step = beat_length * s
		var candidate = round(t / step) * step
		var diff = abs(t - candidate)

		if diff < smallest_diff:
			smallest_diff = diff
			best_snap = candidate

	return best_snap
	
func get_active_subdivisions() -> Array:
	var result := []
	if chart.use_straight:
		result.append_array([1.0, 1/2.0, 1/4.0, 1/8.0])
	if chart.use_triplets:
		result.append_array([1/3.0, 2/3.0])
	return result

# utilities
func sort_notes(times: PackedFloat64Array, columns: PackedInt64Array) -> void:
	var combined := []

	for i in range(times.size()):
		combined.append({
			"time": times[i],
			"col": columns[i]
		})

	combined.sort_custom(func(a, b): return a.time < b.time)

	for i in range(combined.size()):
		times[i] = combined[i].time
		columns[i] = combined[i].col

func _finalize_chart(label: String) -> void:
	chart.emit_changed()

	if chart.resource_path != "":
		var error = ResourceSaver.save(chart, chart.resource_path)
		if error != OK:
			push_error("Failed to save chart! Error: ", error)
	print_debug(label + ": ", chart.note_timings)

# other
func generate_next_beat(subdivision: float) -> void:
	var bpm: float = chart.track.bpm[0.0]

	if chart.note_timings.size() > 0:
		current_note = chart.note_timings[-1]
	else:
		current_note = 0.0

	var beat_length: float = 60.0 / bpm
	var step: float = beat_length * subdivision
	var next_note: float = current_note + step

	var snapped_notes = round(next_note / step) * step

	chart.note_timings.append(snapped_notes)
	chart.note_column.append(0)

	_finalize_chart("generated")


func snap_to_grid_with_key_times(key_times: PackedFloat64Array, key_columns: PackedInt64Array) -> void:
	if not key_times:
		push_warning("No key_times array to snap!")
		return

	chart.note_timings = key_times
	chart.note_column = key_columns
	chart.note_column.resize(chart.note_timings.size())
	chart.note_timings.sort()
	chart.emit_changed()

	if chart.resource_path != "":
		ResourceSaver.save(chart, chart.resource_path)

	print_debug("snapped: ", chart.note_timings)
	print_debug("columns: ", chart.note_column)


func create_key_times(key_times: PackedFloat64Array, start: float, finish: float) -> PackedFloat64Array:
	var result := PackedFloat64Array()
	
	# Keep values OUTSIDE the range
	for value in chart.note_timings:
		if value < start or value > finish:
			result.append(value)

	# Add the new values (already in range)
	result.append_array(key_times)
	
	return result
	
func snap_key_times(key_times: PackedFloat64Array) -> void:
	var bpm: float = chart.track.bpm[0.0]
	
	var beat_length = 60.0 / bpm
	var subdivisions = [1.0, 1/2.0, 1/3.0, 2/3.0]
	var i = 0
	
	for t in key_times:
		var best_snap = t
		var smallest_diff = INF
		for s in subdivisions:
			var step = beat_length * s
			var candidate = round(t / step) * step
			var diff = abs(t - candidate)
			if diff < smallest_diff:
				smallest_diff = diff
				best_snap = candidate
		if i < key_times.size():
			key_times[i] = best_snap
			i += 1
	
	return
	
func _print_test_results(scorecard: Scorecard) -> void:
	var judge = get_parent().get_node("Judge")
	var error_margin = judge.TEMPORAL_ERROR_MARGIN
	var bpm: float = chart.track.bpm[0.0]
	var beat_length = 60.0 / bpm
	
	print("\n" + "=".repeat(75))
	print("      TEST RUN: TARGET TIME vs. YOUR INPUT")
	print("=".repeat(75))
	
	for i in range(scorecard.note_status.size()):
		var state = scorecard.note_status[i]
		var note_time = chart.note_timings[i]
		
		if state == Scorecard.NoteStateEnum.HIT:
			var offset = scorecard.note_temporal_accuracy[i]
			var actual_hit_time = note_time + offset
			var pressed_col = scorecard.note_columns_pressed[i]
			var chart_col = chart.note_column[i]
			
			# Build the context-heavy string
			# Example: Note 05: [Target 2.500s] -> [You 2.541s] | +41.0ms
			var line = "Note %03d: [Target %6.3fs] -> [You %6.3fs] | %+.1f ms" % [
				i, note_time, actual_hit_time, offset * 1000
			]
			
			# Add the Wrong Column warning
			if pressed_col != chart_col:
				line += " !! WRONG COL (%d) !!" % pressed_col
			
			# Add the Nudge suggestion
			var your_snap = get_best_snap(actual_hit_time, beat_length)
			if abs(your_snap - note_time) > 0.001:
				line += " [Nudge to: %.4f]" % your_snap
				
			print(line)
			
		elif state == Scorecard.NoteStateEnum.MISS:
			print("Note %03d: [Target %6.3fs] -> MISSING INPUT" % [i, note_time])

	print("=".repeat(75))
	print("      GHOST INPUTS (NO NOTE ASSIGNED)")
	print("=".repeat(75))

	var ghost_count = 0
	for tap_time in judge.ghost_inputs:
		var is_ghost = true
		for note_time in chart.note_timings:
			if abs(tap_time - note_time) <= error_margin:
				is_ghost = false
				break
		
		if is_ghost:
			ghost_count += 1
			var suggested_snap = get_best_snap(tap_time, beat_length)
			print("GHOST: Pressed at %.3fs | Suggested Snap: %.4f" % [tap_time, suggested_snap])

	print("=".repeat(75))
	print("HITS: %d | MISSES: %d | GHOSTS: %d" % [scorecard.hits, scorecard.misses, ghost_count])
	print("=".repeat(75) + "\n")
