extends CanvasLayer
class_name dialogue_ui

@onready var panel: Control = $Panel
@onready var npc_name: Label = $Panel/Nameplate/Label
@onready var text_label: RichTextLabel = $Panel/RichTextLabel
@onready var enter_prompt: Control = $Panel/EnterPrompt
@onready var ui_enter: Control = $UIprompt

var typing_speed := 0.02  # seconds per character
var typing := false
var full_line := ""
var char_idx := 0
var timer := 0.0

func _ready():
	show()
	panel.hide()
	enter_prompt.hide()
	ui_enter.hide()
	text_label.text = ""
	set_process(false)
	typing = false
	DialogueManager.register_ui(self)
	
func _process(delta):
	if not typing:
		return
	timer += delta
	if timer >= typing_speed:
		timer = 0
		char_idx += 1
		text_label.visible_characters = char_idx
		if char_idx >= full_line.length():
			typing = false
			enter_prompt.show()

	
func show_dialogue(lines: Array, npc_id: String):
	if lines.is_empty():
		return
	panel.show()
	ui_enter.hide()
	enter_prompt.hide()
	npc_name.text = npc_id
	_start_typing(lines[0])
	
func show_line(line: String):
	panel.show()
	_start_typing(line)
	
func hide_dialogue() -> void: 
	panel.hide()
	enter_prompt.hide()
	ui_enter.hide()
	text_label.text = ""
	set_process(false)
	typing = false

func _start_typing(line: String) -> void:
	set_process(true)
	full_line = line
	char_idx = 0
	timer = 0
	typing = true
	text_label.text = full_line
	text_label.visible_characters = 0
	enter_prompt.hide()

func finish_line():
	text_label.visible_characters = -1
	typing = false
	enter_prompt.show()


func show_interaction_prompt():
	enter_prompt.hide()
	panel.hide()
	ui_enter.show()

func hide_interaction_prompt():
	ui_enter.hide()
