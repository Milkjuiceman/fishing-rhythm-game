extends Node

var dialogueUI: dialogue_ui
var active: bool = false

var npc_states: Dictionary = {}

signal quest_started(quest_id)

var npc_quest_order: Dictionary = {
	"dock_npc": ["tutorial_01"]
}

#structure: { npc_id: {quest_id: [dialogue_lines] } }
var dialogue_data: Dictionary = {
	"dock_npc": {
		"": [ "Have you gotten a hang of steering that boat yet?",
				"I know it's a rickety old thing, but it's good enough to keep you afloat in calm waters like these.",
				"That's not what you're here for, though, huh? I promised to teach you the basics!",
				"We'll start with something small - just try to catch a fish in this here lake.",
				"Talk to me again once you've gotten something to show for it!"
		],
		"tutorial_01": {
			"ACTIVE": [
				"Just look for signs of life in the water, like some unusual ripples or sparkles.",
				"Don't sail off too far, now!"
			],
			"COMPLETED": [
				"Nice job! You're a natural, for sure.",
				"The fish up here are more palatable than the ones downstream, but they tend to be much smaller."
			],
			"TURNEDIN": [
				"That means if you want to make a living, you're going to have to get to work!"
			]
		
		}
	}
}

func _init_npc(npc_id: String):
	if not npc_states.has(npc_id):
		npc_states[npc_id] = { "quest_id": "", "line_index": 0, "completed_quests": [] }

func register_ui(ui):
	dialogueUI = ui

func start_dialogue(npc_id: String):
	_init_npc(npc_id)
	var state = npc_states[npc_id]
	var quest_id = state["quest_id"]
	var lines = get_dialogue(npc_id, quest_id)
	if lines.size() > 0:
		active = true
		state["line_index"] = 0
		dialogueUI.show_dialogue([lines[0]])
		
func next_line(npc_id: String):
	_init_npc(npc_id)
	var state = npc_states[npc_id]
	var quest_id = state["quest_id"]
	var lines = get_dialogue(npc_id, quest_id)
	
	state["line_index"] += 1
	
	if state["line_index"] < lines.size():
		dialogueUI.show_dialogue([lines[state["line_index"]]])
	else:
		if QuestManager.get_quest_state(quest_id) == QuestManager.states.COMPLETED:
			QuestManager.turn_in_quest(quest_id)
		_assign_next_quest(npc_id)
		end_dialogue()
		
func end_dialogue():
	active = false
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
	
