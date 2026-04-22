@tool
extends Node

@export var chart: Resource

var current_note: float = 0.0

# Exported buttons
@export_tool_button("Generate next beat") var generate_full_beat
@export_tool_button("Skip a beat") var skip_beat
@export_tool_button("Generate next 1/3 beat") var generate_triplet_beat
@export_tool_button("Generate next 2/3 beat") var generate_2_triplet_beat
@export_tool_button("Generate next 1/8 beat") var generate_eighth_beat
@export_tool_button("Generate next 1/4 beat") var generate_quarter_beat
@export_tool_button("Generate next 1/2 beat") var generate_half_beat
@export_tool_button("Snap Entire Chart") var snap_button

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
	# Assign the buttons programmatically for tool mode
	if Engine.is_editor_hint():
		generate_full_beat = Callable(self, "generate_next_beat").bind(WHOLE)
		skip_beat = Callable(self, "generate_next_beat").bind(DOUBLE)
		generate_triplet_beat = Callable(self, "generate_next_beat").bind(TRIPLET)
		generate_2_triplet_beat = Callable(self, "generate_next_beat").bind(DOUBLE_TRIPLET)
		generate_eighth_beat = Callable(self, "generate_next_beat").bind(EIGHTH)
		generate_quarter_beat = Callable(self, "generate_next_beat").bind(QUARTER)
		generate_half_beat = Callable(self, "generate_next_beat").bind(HALF)
		snap_button = Callable(self, "snap_to_grid")
	return []
	
# input merge pipeline
func _on_receive_key_times(key_times: PackedFloat64Array, key_columns: PackedInt64Array, start: float, finish: float) -> void:
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
		ResourceSaver.save(chart, chart.resource_path)

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

	var snapped = round(next_note / step) * step

	chart.note_timings.append(snapped)
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
