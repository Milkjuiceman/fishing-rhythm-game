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
@export_tool_button("Snap Key Times") var snap_button

# Subdivision constants
const WHOLE = 1.0
const DOUBLE = 2.0
const TRIPLET = 1.0/3.0
const DOUBLE_TRIPLET = 2.0/3.0
const EIGHTH = 1.0/8.0
const QUARTER = 0.25
const HALF = 0.5

func _ready():
	var sender = get_node("/root/RhythmLevel3/Judge")
	sender.send_key_times.connect(_on_receive_key_times)
	
func _on_receive_key_times(key_times: PackedFloat64Array) -> void:
	snap_to_grid_with_key_times(key_times)

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

func generate_next_beat(subdivision: float) -> void:
	var bpm: float = chart.track.bpm[0.0]
	
	if chart.note_timings.size() > 0:
		current_note = chart.note_timings[chart.note_timings.size() - 1]
	else:
		current_note = 0.0
		
	var beat_length: float = 60 / bpm
	var step: float= beat_length * subdivision
	var next_note: float  = current_note + step
		
	chart.note_timings.append(round(next_note / step) * step)
	chart.note_column.append(0)
	print(chart.note_timings)

func snap_to_grid() -> void:
	var bpm: float = chart.track.bpm[0.0]
	var key_times = PackedFloat64Array()

	if not key_times:
		push_warning("No key_times array to snap!")
		return

	var beat_length = 60.0 / bpm
	var subdivisions = [1.0, 1/2.0, 1/3.0, 2/3.0]

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

	print(chart.note_timings)


func snap_to_grid_with_key_times(key_times: PackedFloat64Array) -> void:
	var bpm: float = chart.track.bpm[0.0]

	if not key_times:
		push_warning("No key_times array to snap!")
		return

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
		if i < chart.note_timings.size():
			chart.note_timings[i] = best_snap
			i += 1
		else:
			chart.note_timings.append(best_snap)
			chart.note_column.append(0)

	print(chart.note_timings)
