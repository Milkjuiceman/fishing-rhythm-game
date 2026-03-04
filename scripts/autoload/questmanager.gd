extends Node
class_name QuestManager

signal quest_started(id: String)
signal quest_completed(id: String)
signal quest_turn_in(id: String)

enum QuestState {
	NOT_STARTED,
	ACTIVE,
	COMPLETED,
	TURNED_IN
}

var quests: Dictionary = {} # id -> quest

func _ready():
	InventoryManage.item_changed.connect(update_state)

func init_quest(id: String) -> void:
	if not quests.has(id):
		push_warning("[questmanager] quest already registered: %s" % id)
		return
	var quest = quests[id]
	if quest.state != QuestState.NOT_STARTED:
		return
	quest.state = QuestState.ACTIVE
	emit_signal("quest_started", id)
	
func evaluate_quest(id: String) -> void:
	if not quests.has(id):
		return
	var quest = quests[id]
	if quest.state != QuestState.ACTIVE:
		return
	if quest.is_fulfilled():
		quest.state = QuestState.COMPLETED
		emit_signal("quest_completed", id)
		
		
func fulfill_quest(id: String) -> void:
	if not quests.has(id):
		return
	var quest = quests[id]
	if quest.state != QuestState.COMPLETED:
		return
	quest.evaluate()
	quest.state = QuestState.TURNED_IN
	emit_signal("quest_turned_in", id)

	
func get_quest_state(id: String) -> int:
	if not quests.has(id):
		return QuestState.NOT_STARTED
	return quests[id].state
	
func is_active(id: String) -> bool:
	return get_quest_state(id) == QuestState.ACTIVE
	
func is_completed(id: String) -> bool:
	return get_quest_state(id) == QuestState.COMPLETED
	
func is_turned_in(id: String) -> bool:
	return get_quest_state(id) == QuestState.TURNED_IN

func update_all_quests() -> void:
	for quest in quests.values():
		if quest.state == QuestState.ACTIVE:
			if quest.evaluate_requirements():
				quest.state = QuestState.COMPLETED
				emit_signal("quest_completed", quest.id)


func update_state() -> void:
	update_all_quests()
	
func has_quest(id: String) -> bool:
	return quests.has(id)
	
func get_quest(id: String) -> Quest:
	if not has_quest(id):
		push_warning("[questmanager] quest not found: %s" % id)
		return null
	return quests[id]
	
func register_quest(quest: Quest) -> void:
	if quests.has(quest.id):
		push_warning("[questmanager]: quest already added: %s" % quest.id)
		return
	quests[quest.id] = quest
