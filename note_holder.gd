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
		note.position.x = (chart.note_column[i] - 1.5) * 2;
		i += 1;
			
		if Engine.is_editor_hint():
			note.owner = get_tree().edited_scene_root;
			
		#referee.process.connect(note._on_referee_process);
		#referee.process.connect(Callable(note, "_on_referee_process"))
		#referee.process.connect(note._on_referee_process.bind(note))
