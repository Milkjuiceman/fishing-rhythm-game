@tool

extends Node3D

@export var place_notes: PackedScene;
@export var chart: Chart;
@export var referee: Referee;
@export var note_speed: float;

@export_tool_button("Place notes") var place_notes_action = align_notes;


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
			
		#referee.process.connect(note._on_referee_process);
		#referee.process.connect(Callable(note, "_on_referee_process"))
		#referee.process.connect(note._on_referee_process.bind(note))
