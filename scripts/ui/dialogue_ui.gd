extends CanvasLayer
class_name dialogue_ui

@onready var panel = $Panel
@onready var text_label: RichTextLabel = $Panel/RichTextLabel

var lines: Array = []
var current_index: int = 0
var active := false

func _ready():
	hide()
	DialogueManager.register_ui(self)
	
func _unhandled_input(event):
	if not active:
		return
	if event.is_action_pressed("ui_accept"):
		next_line()

func show_dialogue(new_lines: Array) -> void:
	lines = new_lines
	current_index = 0
	active = true
	show()
	_show_line()
	
func next_line() -> void:
	if not active:
		return
	current_index += 1
	if current_index < lines.size():
		_show_line()
	else:
		hide_dialogue()
	
func hide_dialogue() -> void: 
	active = false
	hide()
	lines.clear()
	current_index = 0
	text_label.text = ""
	
func _show_line() -> void:
	text_label.text = lines[current_index]
