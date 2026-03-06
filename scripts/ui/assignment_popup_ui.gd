extends CanvasLayer
class_name assignment_popup_ui

@onready var panel = $Panel
@onready var description_label = $Panel/VBoxContainer/Description

func _ready():
	hide()
	QuestManager.quest_started.connect(_on_quest_started)
	
func _on_quest_started(quest_id):
	var quest = QuestManager.get_quest(quest_id)
	if quest:
		show_quest(quest.title, quest.description)
		await get_tree().create_timer(3.0).timeout
		hide()

func show_quest(title: String, description: String) -> void:
	show()
	description_label.text = "%s:\n%s" % [title, description]
	
func toggle() -> void:
	if is_visible():
		hide()
	else:
		show()
		
