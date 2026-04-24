@tool
extends Node3D

@export var place_notes: PackedScene;
@export var note_speed: float = 15;

@export_tool_button("Place notes") var place_notes_action = align_notes;

@export var chart: Chart:
	set(value):
		if chart and chart.changed.is_connected(_on_chart_changed):
			chart.changed.disconnect(_on_chart_changed)
		chart = value
		if chart:
			chart.changed.connect(_on_chart_changed)
			# Only auto-align in the editor. 
			# In-game, the Level Editor script will trigger this.
			if Engine.is_editor_hint():
				align_notes()

func _on_chart_changed():
	if Engine.is_editor_hint():
		align_notes()
		

func align_notes() -> void:
	# 1. Clean up old notes
	for note in get_children():
		note.free() # 'free' is more immediate than 'queue_free' for tools
	
	if not chart or not place_notes:
		return

	# 2. Iterate and Instantiate
	for i in range(chart.note_timings.size()):
		var timing = chart.note_timings[i]
		var lane = chart.note_column[i]
		
		var note = place_notes.instantiate() as PlaceNotes
		add_child(note)
		
		# 3. Position based on Time * Speed
		# Z-axis is your "Timeline"
		note.position.z = timing * note_speed
		note.position.x = (lane - 1.5) * 2.0
		note.index = i
		
		# 4. Handle Visuals (Shaders/Labels)
		_apply_note_visuals(note, lane)
			
		# 5. CRITICAL: Only set owner in Editor
		if Engine.is_editor_hint():
			note.owner = get_tree().edited_scene_root

# Helper to keep align_notes clean
func _apply_note_visuals(note: Node3D, lane: int):
	var mat = note.get_surface_override_material(0)
	if mat:
		mat = mat.duplicate() # Make unique
		var lane_colors = [Color.DARK_BLUE, Color.DARK_GREEN, Color.DARK_ORANGE, Color.DARK_RED]
		var color = lane_colors[lane] if lane < lane_colors.size() else Color.WHITE
		
		mat.set_shader_parameter("lane_color", color)
		mat.set_shader_parameter("seed", randf())
		note.set_surface_override_material(0, mat)
		
		var label = note.get_node_or_null("Label3D")
		if label:
			label.modulate = color
