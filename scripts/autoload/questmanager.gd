extends Node

signal active_quests_changed(quests)
signal quest_started(quest_id)

enum states {
	NOT_STARTED,
	ACTIVE,
	COMPLETED,
	TURNEDIN
}

var quests := {
	"tutorial_01": {
		"title": "your first catch",
		"description": "hook a fish in the lake and reel it in!",
		"desc": "catch a fish",
		"from": "dock_npc",
		"goal": 1
	}
}

var quest_states := {}

func _ready(): 
	DialogueManager.quest_started.connect(start_quest)
	_register_all_quests()
	
func _register_all_quests():
	for qid in quests.keys():
		quest_states[qid] = {
			"progress": 0,
			"state": states.NOT_STARTED
		}
	
func start_quest(quest_id: String):
	if not quests.has(quest_id):
		print_debug("Quest not defined:", quest_id)
		return
	var state = quest_states[quest_id]
	if state["state"] == states.NOT_STARTED:
		state["state"] = states.ACTIVE
		print_debug("started:", quests[quest_id]["title"])
		emit_signal("quest_started", quest_id)
		emit_signal("active_quests_changed", get_active_quests())
	

func update_progress(quest_id: String, amount: int):
	if not quest_states.has(quest_id):
		return
	var state = quest_states[quest_id]
	var quest = quests[quest_id]
	if state["state"] == states.ACTIVE:
		state["progress"] += amount
		if state["progress"] >= quest["goal"]:
			state["progress"] = quest["goal"]
			state["state"] = states.COMPLETED
			print_debug("quest completed:", quest["title"])
		emit_signal("active_quests_changed", get_active_quests())

	
func get_quest(quest_id: String):
	if not quests.has(quest_id):
		return null

	var quest = quests[quest_id]
	var state = quest_states[quest_id]

	return {
		"quest_id": quest_id,
		"title": quest["title"],
		"description": quest["description"],
		"desc": quest["desc"],
		"from": quest["from"],
		"goal": quest["goal"],
		"progress": state["progress"],
		"state": state["state"]
	}

func get_quest_state(quest_id: String):
	if quest_states.has(quest_id):
		return quest_states[quest_id]["state"]

	return states.NOT_STARTED


func get_active_quests() -> Dictionary:
	var result := {}
	for qid in quests.keys():
		var quest = quests[qid]
		var state = quest_states[qid]
		if state["state"] == states.ACTIVE:
			result[qid] = {
				"title": quest["title"],
				"description": quest["description"],
				"desc": quest["desc"],
				"from": quest["from"],
				"progress": state["progress"],
				"goal": quest["goal"]
			}
	return result
