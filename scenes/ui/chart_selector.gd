@tool # This makes the code run in the Editor
extends Control

@export var charts_dir: String = "res://assets/tracks/charts/"
var list_container: VBoxContainer

func _ready() -> void:
	print("[DEBUG] Tool script ready!")
	_refresh_list()
	
func _refresh_list() -> void:
	list_container = get_node_or_null("ScrollContainer/VBoxContainer")
	if not list_container: 
		print("[DEBUG] Error: Could not find VBoxContainer")
		return

	# Clear existing buttons
	for child in list_container.get_children():
		child.free()
	
	print("[DEBUG] Checking directory: ", charts_dir)
	var dir = DirAccess.open(charts_dir)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if not dir.current_is_dir() and (file_name.ends_with(".tres") or file_name.ends_with(".tres.remap")):
				_create_chart_button(file_name.replace(".remap", ""), list_container)
			file_name = dir.get_next()
	else:
		print("[DEBUG] Error: Directory not found at ", charts_dir)

func _create_chart_button(file_name: String, container: Node) -> void:
	var btn = Button.new()
	btn.text = file_name.get_basename().capitalize()
	btn.custom_minimum_size.y = 50 # Ensure it has height
	
	container.add_child(btn)
	if Engine.is_editor_hint():
		btn.owner = get_tree().edited_scene_root
	btn.pressed.connect(func():
		_on_chart_selected(file_name)
	)

func _on_chart_selected(file_name: String) -> void:
	var chart_path = charts_dir + file_name
	var selected_chart = load(chart_path)
	if selected_chart:
		GameStateManager.current_selected_chart = selected_chart
		GameStateManager.editor_testing_mode = true 
		GameStateManager.last_played_track_name = file_name.get_basename()
		print("[Launcher] Swapping to Editor with: ", file_name)
		get_tree().change_scene_to_file("res://rhythm/Editor/rhythm_level_editor.tscn")
	
