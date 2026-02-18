@tool
extends Node

@export var chart: Resource

var bpm: float = chart.track.bpm[0.0]
var song_length: float = chart.track.song_length
var timings: PackedFloat64Array = chart.note_timings
var current_note: float = 0.0

# Exported buttons
@export_tool_button("Generate next beat") var generate_full_beat
@export_tool_button("Skip a beat") var skip_beat
@export_tool_button("Generate next 1/3 beat") var generate_triplet_beat
@export_tool_button("Generate next 2/3 beat") var generate_2_triplet_beat
@export_tool_button("Generate next 1/8 beat") var generate_eighth_beat
@export_tool_button("Generate next 1/4 beat") var generate_quarter_beat
@export_tool_button("Generate next 1/2 beat") var generate_half_beat

# Subdivision constants
const WHOLE = 1.0
const DOUBLE = 2.0
const TRIPLET = 1.0/3.0
const DOUBLE_TRIPLET = 2.0/3.0
const EIGHTH = 1.0/8.0
const QUARTER = 0.25
const HALF = 0.5

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
	return []

func generate_next_beat(subdivision: float) -> void:
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
