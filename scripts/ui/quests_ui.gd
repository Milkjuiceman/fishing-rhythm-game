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
		label.add_theme_font_size_override("font_size", 16)
		label.text = "%s:\n%s" % [quest_info.title, quest_info.desc]
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.custom_minimum_size = Vector2(200, 0)
		quest_list_container.add_child(label)
