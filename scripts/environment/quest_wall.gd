extends StaticBody3D
## QuestWall
## Invisible wall that disables itself when the player reaches a certain quest.

@export var unlock_at_quest: String = ""

func _ready() -> void:
	var current_idx = QuestManager.QUEST_ORDER.find(QuestManager.current_quest_id)
	var unlock_idx = QuestManager.QUEST_ORDER.find(unlock_at_quest)
	
	if unlock_idx != -1 and current_idx >= unlock_idx:
		# Already past this quest — wall is already open
		queue_free()
		return
	
	# Wait for the quest to be reached
	QuestManager.quest_started.connect(_on_quest_started)

func _on_quest_started(quest_id: String) -> void:
	if quest_id == unlock_at_quest:
		queue_free()
