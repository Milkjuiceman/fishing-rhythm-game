@tool

extends Node3D
## Generates and aligns note instances in the editor based on chart timing and lane data.
## Acts as a bridge between Chart data and visual note placement for level design.
## Author: Tyler Schauermann
## Date of last update: 04/02/2026
## Designed for editor-time note generation, can be extended for runtime spawning
## or dynamic chart visualization systems.

# ========================================
# CONSTANTS AND EXPORTED VARIABLES
# ========================================

# Packed scene used to instantiate note objects
@export var place_notes: PackedScene;

# Chart containing note timings and lane data
@export var chart: Chart;

# Reference to referee for signal connections
@export var referee: Referee;

# Reference to judge for note judgment signals
@export var judge: RhythmJudge;

# Speed multiplier for note positioning
@export var note_speed: float;

# Editor button to trigger note placement
@export_tool_button("Place notes") var place_notes_action = align_notes;

# ========================================
# INITIALIZATION
# ========================================

# Connects note_judged signal to all existing notes
func _ready() -> void:
	for note in get_children():
		judge.connect("note_judged", Callable(note, "_on_note_judged"))

# ========================================
# NOTE PLACEMENT / ALIGNMENT
# ========================================

# Clears and regenerates notes based on chart data
func align_notes() -> void:
	for note in get_children():
		note.queue_free();
	
	var i: int;
	i = 0;
	for timing in chart.note_timings:
		var note: PlaceNotes;
		note = place_notes.instantiate();
		add_child(note);
		note.position.z = timing * note_speed;
		var lane = chart.note_column[i]
		note.position.x = (lane - 1.5) * 2
		note.index = i
		print(note.index)
		set_editable_instance(note, true)

		# Apply to shader
		var mat = note.get_surface_override_material(0).duplicate(true)
		# Get the label
		var label = note.get_node("Label3D") as Label3D
		if mat:
			mat = mat.duplicate()  # make it unique per note
			mat.set_shader_parameter("seed", randf())
			match lane:
				0:
					mat.set_shader_parameter("lane_color", Color.DARK_BLUE)
					label.modulate = Color.DARK_BLUE
				1:
					mat.set_shader_parameter("lane_color", Color.DARK_GREEN)
					label.modulate = Color.DARK_GREEN
				2:
					mat.set_shader_parameter("lane_color", Color.DARK_ORANGE)
					label.modulate = Color.DARK_ORANGE
				3:
					mat.set_shader_parameter("lane_color", Color.DARK_RED)
					label.modulate = Color.DARK_RED
				_:
					mat.set_shader_parameter("lane_color", Color.WHITE)
					label.modulate = Color.WHITE
			note.set_surface_override_material(0, mat)
		i += 1;
			
		if Engine.is_editor_hint():
			note.owner = get_tree().edited_scene_root;
