extends Node

var quests: Dictionary = {}
signal quest_started(quest_id: String)
signal quest_completed(quest_id)
signal quest_turnedin(quest_id)

enum states {
	NOT_STARTED,
	ACTIVE,
	COMPLETED,
	TURNED_IN
}

func register_quest(q: Quest):
	quests[q.quest_id] = q

func get_quest(quest_id: String) -> Quest:
	if quests.has(quest_id): return quests[quest_id]
	return null
	
func start_quest(quest_id: String):
	var q = get_quest(quest_id)
	if q and not q.completed:
		print_debug("assigning quest: ", q.title)
		emit_signal("quest_started", quest_id)
		return q
	return null
	
