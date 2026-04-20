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
		},
		# Repeatable lines shown after all quests are done.
		# Only one line is shown per interaction — cycles through the list.
		"idle": [
			"The fish up here aren't going anywhere. Get back out there!",
			"Keep at it. The more you fish, the better you'll get.",
			"You're doing great. Don't let me down!"
		]
	}
}

# ========================================
# INITIALIZATION
# ========================================

func _ready() -> void:
	QuestManager.quest_started.connect(_on_quest_started)

func _on_quest_started(quest_id: String) -> void:
	for npc_id in npc_quest_order.keys():
		if quest_id in npc_quest_order[npc_id]:
			_init_npc(npc_id)
			var state = npc_states[npc_id]
			if state["quest_id"] == "":
				state["quest_id"] = quest_id

# ========================================
# NPC STATE
# ========================================

func _init_npc(npc_id: String):
	if not npc_states.has(npc_id):
		npc_states[npc_id] = {
			"quest_id": "",
			"line_index": 0,
			"current_lines": [],
			"completed_quests": [],
			"idle_index": 0,    # tracks position in idle cycle
			"all_done": false   # true once all quests are turned in
		}

func register_ui(ui):
	dialogueUI = ui

# ========================================
# DIALOGUE FLOW
# ========================================

func start_dialogue(npc_id: String):
	_init_npc(npc_id)
	current_npc = npc_id
	var state = npc_states[npc_id]

	# If all quests are done, show the next idle line and exit
	if state["all_done"]:
		_show_idle_line(npc_id)
		return

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
		state["completed_quests"].append(quest_id)

		var turnin_lines = get_dialogue(npc_id, quest_id)
		if turnin_lines.size() > 0:
			state["line_index"] = 0
			state["current_lines"] = turnin_lines
			dialogueUI.show_line(turnin_lines[0])
			return

	_assign_next_quest(npc_id)
	end_dialogue()

func end_dialogue():
	active = false
	current_npc = ""
	for state in npc_states.values():
		state["current_lines"] = []
		state["line_index"] = 0
	if dialogueUI:
		dialogueUI.hide_dialogue()

# ========================================
# IDLE DIALOGUE (repeatable, post-quest)
# ========================================

func _show_idle_line(npc_id: String) -> void:
	var state = npc_states[npc_id]
	var npc_dialogue = dialogue_data.get(npc_id, {})
	var idle_lines: Array = npc_dialogue.get("idle", [])

	if idle_lines.is_empty():
		return

	# Pick the next line in the cycle, wrapping around
	var idx = state["idle_index"] % idle_lines.size()
	state["idle_index"] += 1

	if dialogueUI:
		active = true
		dialogueUI.show_dialogue([idle_lines[idx]], npc_id)

# ========================================
# DIALOGUE LOOKUP
# ========================================

func get_dialogue(npc_id: String, quest_id: String = "") -> Array:
	if not dialogue_data.has(npc_id):
		return []
	var npc_dialogue = dialogue_data[npc_id]
	if quest_id == "":
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
				return qdata.get("TURNEDIN", [])
	return []

# ========================================
# QUEST ASSIGNMENT
# ========================================

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
	# No more quests — switch to idle mode
	state["quest_id"] = ""
	state["all_done"] = true

# ========================================
# HELPERS
# ========================================

func has_new_lines(npc_id: String) -> bool:
	_init_npc(npc_id)
	var state = npc_states[npc_id]

	# Idle NPCs always have something to say
	if state["all_done"]:
		var npc_dialogue = dialogue_data.get(npc_id, {})
		return not npc_dialogue.get("idle", []).is_empty()

	var quest_id = state["quest_id"]
	var lines = get_dialogue(npc_id, quest_id)
	return lines.size() > 0

func get_current_lines() -> Array:
	if current_npc == "":
		return []
	var state = npc_states.get(current_npc, null)
	if state and state.has("current_lines"):
		return state["current_lines"]
	return []
