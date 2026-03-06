extends Node

var dialogueUI: dialogue_ui
var active: bool = false
var current_npc: String = ""

var npc_states: Dictionary = {}

signal quest_started(quest_id)

var npc_quest_order: Dictionary = {
	"dock_npc": ["tutorial_01"]
}

#structure: { npc_id: {quest_id: [dialogue_lines] } }
var dialogue_data: Dictionary = {
	"dock_npc": {
		"": [   "Congrats on your first boat! Have you gotten a hang of steering that old thing yet?",
				"I know it's nothing special, but it's good enough to keep you afloat in calm waters like these.",
				"But you're not here for a sailing lesson, though, huh? I promised to show you how to use that old fishing rod!",
				"We'll start with something easy - just try to catch a fish in this here lake.",
				"Talk to me again once you've gotten something to show for it!"
		],
		"tutorial_01": {
			"ACTIVE": [
				"Just look for signs of life in the water, like some unusual ripples or sparkles.",
				"Don't sail off too far, now!"
			],
			"COMPLETED": [
				"Nice job! You're a natural.",
				"The fish up here are cleaner than the ones downstream, but they tend to be much smaller."
			],
			"TURNEDIN": [
				"That means if you want to make a living, you're going to have to get to work!"
			]
		
		}
	}
}

func _init_npc(npc_id: String):
	if not npc_states.has(npc_id):
		npc_states[npc_id] = {
			"quest_id": "",
			"line_index": 0,
			"current_lines": [],
			"completed_quests": []
	}

func register_ui(ui):
	dialogueUI = ui

func start_dialogue(npc_id: String):
	_init_npc(npc_id)
	current_npc = npc_id
	var state = npc_states[npc_id]
	var quest_id = state["quest_id"]
	var lines = get_dialogue(npc_id, quest_id)
	if lines.size() > 0:
		state["line_index"] = 0
		state["current_lines"] = lines
		if dialogueUI:
			dialogueUI.show_dialogue(lines, npc_id)
			active = true
		
func next_line(npc_id: String):
	_init_npc(npc_id)
	var state = npc_states[npc_id]

	if state["current_lines"].is_empty():
		return
	
	state["line_index"] += 1
	var lines = state["current_lines"]
	
	if state["line_index"] < lines.size():
		dialogueUI.show_line(lines[state["line_index"]])
		return

	var quest_id = state["quest_id"]
	var quest_state = QuestManager.get_quest_state(quest_id)
	
	if quest_state == QuestManager.states.COMPLETED:
		QuestManager.turn_in_quest(quest_id)
		quest_state = QuestManager.states.TURNEDIN  # update locally
	var next_lines = get_dialogue(npc_id, quest_id)
	if next_lines.size() > 0 and quest_state == QuestManager.states.TURNEDIN:
		state["line_index"] = 0
		state["current_lines"] = next_lines
		dialogueUI.show_line(next_lines[0])
	else:
		# Otherwise, assign next quest or end dialogue
		_assign_next_quest(npc_id)
		end_dialogue()

		
func end_dialogue():
	active = false
	current_npc = ""
	for state in npc_states.values():
		state.erase("current_lines")
		state["line_index"] = 0
	if dialogueUI:
		dialogueUI.hide_dialogue()

func get_dialogue(npc_id: String, quest_id: String = "") -> Array:
	if not dialogue_data.has(npc_id):
		return []
	var npc_dialogue = dialogue_data[npc_id]
	if quest_id ==  "":
		return npc_dialogue.get("", [])
	var quest_state = QuestManager.get_quest_state(quest_id)
	if npc_dialogue.has(quest_id):
		var qdata = npc_dialogue[quest_id]
		match quest_state:
			QuestManager.states.ACTIVE:
				return qdata.get("ACTIVE", [])
			QuestManager.states.COMPLETED:
				return qdata.get("COMPLETED", [])
			QuestManager.states.TURNEDIN:
				return qdata.get("TURNIN", [])
	return []

func _assign_next_quest(npc_id: String):
	_init_npc(npc_id)
	var state = npc_states[npc_id]
	var completed = state["completed_quests"]
	var quest_list = npc_quest_order.get(npc_id, [])
	for qid in quest_list:
		if not completed.has(qid):
			state["quest_id"] = qid
			emit_signal("quest_started", qid)
			return
	state["quest_id"] = ""
	
func has_new_lines(npc_id: String) -> bool:
	_init_npc(npc_id)
	var state = npc_states[npc_id]
	var quest_id = state["quest_id"]
	var lines = get_dialogue(npc_id, quest_id)
	return state["line_index"] < lines.size()
	
func get_current_lines() -> Array:
	if current_npc == "":
		return []
	var state = npc_states.get(current_npc, null)
	if state and state.has("current_lines"):
		return state["current_lines"]
	return []
