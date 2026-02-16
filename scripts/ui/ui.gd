extends CanvasLayer

@onready var interact_prompt = $prompt
@onready var dialogue_box = $dialoguebox
@onready var dialogue_text = $dialoguebox/textbox

var player_in_range := false
var dialogue_open := false
var dialogue_lines: Array =  []
var current_line := 0

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	dialogue_box.visible = false
	interact_prompt.visible = false

	
func show_prompt():
	player_in_range = true
	_update_prompt()
	
func hide_prompt():
	player_in_range = false
	_update_prompt()
	
func start_dialogue(lines: Array):
	if dialogue_open:
		return
	dialogue_lines = lines
	current_line = 0
	dialogue_open = true
	dialogue_box.visible = true
	call_deferred("_show_current_line")
	_update_prompt()

func advance_dialogue():
	if not dialogue_open: 
		return
	current_line += 1
	if current_line < dialogue_lines.size():
		_show_current_line()
	else:
		close_dialogue()
		
func close_dialogue():
	dialogue_open = false
	dialogue_box.visible = false
	_update_prompt()
	
func is_dialogue_open() -> bool:
	return dialogue_open
	
func _show_current_line():
	if dialogue_lines.size() > 0:
		dialogue_text.text = dialogue_lines[current_line]
	
func _update_prompt():
	interact_prompt.visible = player_in_range and not dialogue_open
