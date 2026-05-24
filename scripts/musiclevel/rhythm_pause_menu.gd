extends Control
## Rhythm Pause Menu (Autoload)
## Only activates when a Rhythm group node is present (i.e. inside a rhythm level).
## Tab toggles pause, Enter resumes.

@onready var panel: Panel = $Panel

var is_paused: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	panel.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	if not event.pressed or event.echo:
		return

	match event.keycode:
		KEY_TAB:
			if _in_rhythm_level():
				_toggle_pause()
				get_viewport().set_input_as_handled()
		KEY_ENTER, KEY_KP_ENTER:
			if is_paused:
				_resume()
				get_viewport().set_input_as_handled()


func _in_rhythm_level() -> bool:
	return get_tree().get_nodes_in_group("Rhythm").size() > 0


func _toggle_pause() -> void:
	if is_paused:
		_resume()
	else:
		_pause()


func _pause() -> void:
	is_paused = true
	get_tree().paused = true
	visible = true
	panel.visible = true


func _resume() -> void:
	is_paused = false
	get_tree().paused = false
	visible = false
	panel.visible = false
