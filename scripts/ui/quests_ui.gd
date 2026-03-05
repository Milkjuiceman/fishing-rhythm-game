extends CanvasLayer
class_name quest_ui

@onready var panel: Panel = $Panel
@onready var quest_list_container: VBoxContainer = $Panel/MarginContainer/VBoxContainer

func _ready():
	hide()
	QuestManager.active_quests_changed.connect(_refresh)
	_refresh(QuestManager.get_active_quests())
	
func toggle():
	if is_visible():
		hide()
	else:
		show()
		
func _refresh(active_quests: Dictionary): 
	for child in quest_list_container.get_children():
		child.queue_free()
		
	for quest_id in active_quests.keys():
		var quest_info = active_quests[quest_id]
		var label = Label.new()
		label.text = "%s:\n ~ %s (%d/%d)" % [quest_info.title, quest_info.desc, quest_info.progress, quest_info.goal]
		quest_list_container.add_child(label)
