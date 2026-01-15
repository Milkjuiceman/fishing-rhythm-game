extends CanvasLayer

@export var player_node: NodePath
@onready var player = get_node(player_node)

@onready var interact_prompt = $prompt
@onready var dialogue_box = $dialoguebox
@onready var dialogue_text = $dialoguebox/textbox

var player_in_range: bool = false
var dialogue_open: bool = false
var dialogue_lines: Array =  []
var current_line: int = 0

# public methods	
func player_enters_interzone():
	player_in_range = true
	_update_prompt()
	
func player_exits_interzone():
	player_in_range = false
	_update_prompt()
	
func start_dialogue(lines: Array):
	if dialogue_open:
		return
	dialogue_lines = lines
	current_line = 0
	dialogue_open = true
	dialogue_box.visible = true
	_display_current_line()
	_update_prompt()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
func hide_dialogue():
	dialogue_open = false
	dialogue_box.visible = false
	_update_prompt()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
#internal
func _update_prompt():
	interact_prompt.visible = player_in_range and not dialogue_open
	
func _display_current_line():
	if current_line < dialogue_lines.size():
		dialogue_text.text = dialogue_lines[current_line]
		
#input handling
func _unhandled_input(event):
	if dialogue_open and event.is_action_pressed("interact"):
		current_line += 1
		if current_line < dialogue_lines.size():
			_display_current_line()
		else:
			hide_dialogue() 
	elif dialogue_open and event.is_action_pressed("ui_cancel"):
		hide_dialogue()
