extends Node
## DialogueManager Autoload
## Manages all NPC dialogue, quest assignment, and conversation flow.
## Author: Tyler Schauermann
## Date of last update: 04/22/2026

var dialogueUI: dialogue_ui
var active: bool = false
var current_npc: String = ""

var npc_states: Dictionary = {}

signal quest_started(quest_id)

# ========================================
# QUEST ORDER PER NPC
# ========================================

var npc_quest_order: Dictionary = {
	"dock_npc": ["tutorial_01", "tutorial_02"],
	"lake_npc":  ["tutorial_03", "tutorial_04"],
}

# ========================================
# DIALOGUE DATA
# ========================================
# Special keys:
#   "pre_quest"  — shown when the player talks to this NPC before it's their turn
#                  in the story. Does NOT assign a quest or advance state.
#   ""           — real intro, shown once when it IS this NPC's turn
#   "quest_id"   — { "ACTIVE": [], "COMPLETED": [], "TURNEDIN": [] }
#   "idle"       — cycling lines shown after all quests are complete

var dialogue_data: Dictionary = {

	# ── DOCK NPC ──────────────────────────────────────────────────────────
	"dock_npc": {
		"": [
			"Congrats on your first boat! Have you gotten a hang of steering that old thing yet?",
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
				"The fish up here are cleaner than the ones downstream, but they tend to be much smaller.",
			],
			"TURNEDIN": [
				"There's another fisher on the far side of the lake — been out here longer than I have.",
				"Head over and introduce yourself. Could be worth your while."
			]
		},
		"tutorial_02": {
			"ACTIVE": [
				"They're on the other side of the lake. Go say hello!",
			],
			# tutorial_02 completes when the player reaches lake_npc,
			# so dock_npc won't show COMPLETED. Leave empty.
			"COMPLETED": [],
			"TURNEDIN": [
				"Good to hear you two met. Now get back out there!"
			]
		},
		"idle": [
			"The fish up here aren't going anywhere. Get back out there!",
			"Keep at it. The more you fish, the better you'll get.",
			"You're doing great. Don't let me down!"
		]
	},

	# ── LAKE NPC ──────────────────────────────────────────────────────────
	"lake_npc": {
		# Shown when the player reaches lake_npc BEFORE tutorial_01 is turned in.
		# Does not assign a quest — just friendly deflection.
		"pre_quest": [
			"Oh! Didn't expect a visitor.",
			"You look new. Go get your bearings first — there's a fisher back at the dock who can help.",
			"Come find me once you've caught something."
		],
		# Shown the first time the player arrives AFTER tutorial_01 is turned in.
		"": [
			"Oh! A newcomer. Don't see many fresh faces out this way.",
			"The name's Fen. I've been fishing these waters since before you were born.",
			"You've caught one already? Not bad. But one fish doesn't make a fisher.",
			"Tell you what — come back once you've caught all three kinds that live in this lake.",
			"Then we'll talk about what lies beyond."
		],
		"tutorial_03": {
			"ACTIVE": [
				"Still working on it? The three fish are out there — keep at it.",
				"Each spot on the water hides something different. Stay patient."
			],
			"COMPLETED": [
				"Well I'll be. You actually did it.",
				"Three different fish from the same lake. You've got a good feel for this.",
				"There's a whole world past this lake. Head downstream when you're ready.",
			],
			"TURNEDIN": [
				"The current will take you there. Good luck out there."
			]
		},
		"tutorial_04": {
			"ACTIVE": [
				"What are you still doing here? Head downstream — the next area is waiting.",
			],
			"COMPLETED": [],
			"TURNEDIN": []
		},
		"idle": [
			"Still here? The downstream waters are calling.",
			"You've earned your place out there. Don't keep them waiting.",
		]
	},
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
			"idle_index": 0,
			"all_done": false,
			"intro_seen": false  # true once the "" intro block has fully played
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

	if state["all_done"]:
		_show_idle_line(npc_id)
		return

	# ── lake_npc gate ─────────────────────────────────────────────────────
	# If tutorial_01 isn't turned in yet, show deflection lines — no quest.
	if npc_id == "lake_npc" and not state["intro_seen"]:
		var t01 = QuestManager.get_quest_state("tutorial_01")
		if t01 != QuestManager.states.TURNEDIN:
			_show_lines(npc_id, dialogue_data["lake_npc"].get("pre_quest", []))
			return
	# ─────────────────────────────────────────────────────────────────────

	var quest_id = state["quest_id"]
	var lines = get_dialogue(npc_id, quest_id)
	if lines.size() > 0:
		_show_lines(npc_id, lines)

func _show_lines(npc_id: String, lines: Array) -> void:
	if lines.is_empty():
		return
	var state = npc_states[npc_id]
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

	# End of current line set — figure out what comes next.

	# ── lake_npc pre_quest ending ─────────────────────────────────────────
	# Just finished the deflection block — close without assigning anything.
	if npc_id == "lake_npc" and not state["intro_seen"]:
		var t01 = QuestManager.get_quest_state("tutorial_01")
		if t01 != QuestManager.states.TURNEDIN:
			end_dialogue()
			return
	# ─────────────────────────────────────────────────────────────────────

	var quest_id = state["quest_id"]
	var quest_state = QuestManager.get_quest_state(quest_id)

	# Mark intro seen once the "" block finishes
	if not state["intro_seen"] and quest_id == "":
		state["intro_seen"] = true

	if quest_state == QuestManager.states.COMPLETED:
		QuestManager.turn_in_quest(quest_id)
		state["completed_quests"].append(quest_id)

		var turnin_lines = get_dialogue(npc_id, quest_id)
		if turnin_lines.size() > 0:
			state["line_index"] = 0
			state["current_lines"] = turnin_lines
			dialogueUI.show_line(turnin_lines[0])
			return

	# ── talking to lake_npc completes tutorial_02 ─────────────────────────
	if npc_id == "lake_npc":
		var t02_state = QuestManager.get_quest_state("tutorial_02")
		if t02_state == QuestManager.states.ACTIVE:
			QuestManager.update_progress("tutorial_02", 1)
	# ─────────────────────────────────────────────────────────────────────

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
# IDLE DIALOGUE
# ========================================

func _show_idle_line(npc_id: String) -> void:
	var state = npc_states[npc_id]
	var npc_dialogue = dialogue_data.get(npc_id, {})
	var idle_lines: Array = npc_dialogue.get("idle", [])
	if idle_lines.is_empty():
		return
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
	state["quest_id"] = ""
	state["all_done"] = true

# ========================================
# HELPERS
# ========================================

func has_new_lines(npc_id: String) -> bool:
	_init_npc(npc_id)
	var state = npc_states[npc_id]

	if state["all_done"]:
		var npc_dialogue = dialogue_data.get(npc_id, {})
		return not npc_dialogue.get("idle", []).is_empty()

	# lake_npc: always has something (pre_quest or real lines)
	if npc_id == "lake_npc" and not state["intro_seen"]:
		return true

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
