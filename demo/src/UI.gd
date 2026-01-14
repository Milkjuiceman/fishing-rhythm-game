extends Control

var visible_mode: int = 1
@export var player_node: NodePath
@onready var player = get_node(player_node)

@onready var interact_prompt = $interaction
@onready var dialogue_box = $dialogue
@onready var dialogue_text = $dialogue/textbox

var dialogue_lines: Array = []
var current_line: int = 0
var player_in_range := false
var dialogue_open := false


func _init() -> void:
	RenderingServer.set_debug_generate_wireframes(true)


func _process(p_delta) -> void:
	$Label.text = "FPS: %s\n" % str(Engine.get_frames_per_second())
	if(visible_mode == 1):
		$Label.text += "Move Speed: %.1f\n" % player.MOVE_SPEED if player else ""
		$Label.text += "Position: %.1v\n" % player.global_position if player else ""
		$Label.text += """
			Player Controls
			Move: WASDEQ
			Jump: Space
			Interact: Enter
			Move speed: Wheel, +/-
			Camera View: V
			Gravity toggle: G
			Collision toggle: C

			Window
			Quit: F8
			UI toggle: F9
			Render mode: F10
			Full screen: F11
			Mouse toggle: Escape / F12
			"""


func _unhandled_key_input(p_event: InputEvent) -> void:
	if dialogue_open and p_event.is_action_pressed("interact"):
		current_line += 1
		if current_line < dialogue_lines.size():
			_display_current_line()
		else:
			hide_dialogue() 
	elif dialogue_open and p_event.is_action_pressed("ui_cancel"):
		hide_dialogue()
	if p_event is InputEventKey and p_event.pressed:
		match p_event.keycode:
			KEY_F8:
				get_tree().quit()
			KEY_F9:
				visible_mode = (visible_mode + 1 ) % 3
				$Label/Panel.visible = (visible_mode == 1)
				visible = visible_mode > 0
			KEY_F10:
				var vp = get_viewport()
				vp.debug_draw = (vp.debug_draw + 1 ) % 6
				get_viewport().set_input_as_handled()
			KEY_F11:
				toggle_fullscreen()
				get_viewport().set_input_as_handled()
			KEY_ESCAPE, KEY_F12:
				if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
					Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
				else:
					Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
				get_viewport().set_input_as_handled()
		
		
func toggle_fullscreen() -> void:
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN or \
		DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(Vector2(1280, 720))
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)

func _update_interact_prompt():
	interact_prompt.visible = player_in_range and not dialogue_open
	
func player_enters_interzone():
	player_in_range = true
	_update_interact_prompt()
	
func player_exits_interzone():
	player_in_range = false
	_update_interact_prompt()
	
func start_dialogue(lines: Array):
	if not lines or dialogue_open:
		return
	dialogue_lines = lines
	current_line = 0
	dialogue_open = true
	dialogue_box.visible = true
	dialogue_text.clear()
	_display_current_line()
	_update_interact_prompt()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func hide_dialogue():
	dialogue_open = false
	dialogue_box.visible = false
	_update_interact_prompt()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
func _display_current_line():
	if current_line < dialogue_lines.size():
		dialogue_text.text = dialogue_lines[current_line]
