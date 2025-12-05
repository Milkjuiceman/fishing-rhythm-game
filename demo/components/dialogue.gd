extends Control

@onready var dialogue_label = $nameplate
var dialogue_lines = []
var curr_line = 0
var is_active = false

func start_dialogue(lines: Array):
	dialogue_lines = lines
	curr_line= 0
	is_active = true
	visible = true
	show_line()
	
func show_line():
	if curr_line < dialogue_lines.size():
		dialogue_label.text = dialogue_lines[curr_line]
	else:
		end_dialogue()

func end_dialogue():
	visible = false
	is_active = false
	
func _input(event):
	if is_active and event.is_action_pressed("interact"):
		curr_line += 1
		show_line()
