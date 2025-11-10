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
	
	for timing in chart.note_timings:
		var note: PlaceNotes;
		note = place_notes.instantiate();
		add_child(note);
		note.position.z = timing * note_speed;
		
		if Engine.is_editor_hint():
			note.owner = get_tree().edited_scene_root;
			
		#referee.process.connect(note._referee_process);
