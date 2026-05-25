extends Node
## DialogueManager Autoload
## Drives all NPC conversation and quest progression.
##
## DESIGN:
##   - One quest active at a time (QuestManager.current_quest_id).
##   - Talking to an NPC triggers a single decision:
##       1. Is this the NPC the current quest is pointing to?
##       2. If it's a talk quest  -> show intro lines, advance quest at end.
##       3. If it's a catch quest -> check fish count now; if done show
##          completion lines and advance; otherwise show "keep trying" lines.
##   - No per-NPC state machines. No intro_seen flags. No quest order lists.
##   - Every NPC has: pre_lines (wrong time), complete_lines (quest done here),
##     waiting_lines (right NPC, quest not done yet), idle_lines (all done).
## Author: Tyler Schauermann
## Date of last update: 05/23/2026

signal quest_started(quest_id)  # kept for RipplingWaterSpawner compatibility

var dialogueUI: dialogue_ui
var active: bool = false
var current_npc: String = ""

# Lines currently being shown + cursor
var _lines: Array = []
var _line_idx: int = 0
var _advance_on_end: bool = false  # if true, call QuestManager.advance_quest() when lines finish

# ========================================
# DIALOGUE DATA
# ========================================
# Per NPC:
#   "pre"      — shown when player talks to this NPC but it's not their turn yet
#   "complete" — shown when the player has satisfied the quest and talks to this NPC
#                (advance_quest fires at the end of these lines)
#   "waiting"  — shown when it IS this NPC's turn but the condition isn't met yet
#   "idle"     — shown after this NPC's quest chain is finished

var dialogue: Dictionary = {

	# ── GRAMPS (dock NPC, tutorial lake) ──────────────────────────────────
	"gramps": {
		"pre": [
			"Welcome! Go get your bearings first.",
		],
		"complete": [
			# q1 complete: player talked to Gramps. Give q2 (catch 1 fish).
			"Congrats on your first boat! She's nothing fancy but she'll keep you afloat.",
			"Here, take this old rod. Try to hook something in this lake.",
			"Come back once you've caught your first fish!",
		],
		"waiting": [
			# q2 active, player back before catching anything
			"No fish yet? The water's full of them — keep looking for ripples!",
		],
		"q2_done": [
			# q2 complete: player caught 1 fish and talks to Gramps. Give q3 (talk to Paul).
			"Ha! Look at that! Not bad for a first timer.",
			"The fish here are small but clean. There's another fisher across the lake — name's Paul.",
			"Head over and introduce yourself. He's been out here a lot longer than me.",
		],
		"idle": [
			"The fish aren't going anywhere. Get back out there!",
			"Keep at it. You're doing great.",
		],
	},

	# ── PAUL (lake NPC, tutorial lake) ────────────────────────────────────
	"paul": {
		"pre": [
			"Oh! Didn't expect a visitor. Go talk to the fisher at the dock first.",
		],
		"complete": [
			# q3 complete: player talked to Paul. Give q4 (catch 3 fish).
			"Well hello there! Gramps sent you? Good man.",
			"This lake has three different kinds of fish hiding in it.",
			"Catch one of each and come back — I want to see what you're made of.",
		],
		"waiting": [
			"Still working on it? Three different fish — you can do it.",
			"Each ripple spot hides something different. Stay patient.",
		],
		"q4_done": [
			# q4 complete: player caught 3 fish and talks to Paul. Give q5 (talk to Tim).
			"Three different fish! You've got a real feel for this.",
			"There's a whole world past this lake. Head to the lake intersection.",
			"Find Tim at the main dock there. Tell him I sent you.",
		],
		"idle": [
			"The intersection is waiting. Don't keep Tim standing around.",
		],
	},

	# ── TIM (main dock NPC, lake intersection) ─────────────────────────────
	"tim": {
		"pre": [
			"Welcome to the intersection. Come back when Paul sends you.",
		],
		"complete": [
			# q5 complete: player talked to Tim. Give q6 (catch 3 fish in intersection).
			"Paul's student, huh? Welcome to the intersection.",
			"These waters branch off everywhere from here. Good place to sharpen your skills.",
			"Catch two fish in this area first — then we'll talk about what's further out.",
		],
		"waiting": [
			"Two fish from this area. You're close — keep going.",
		],
		"q6_done": [
			# q6 complete: player caught 3 intersection fish and talks to Tim. Give q7 (talk to Chad).
			"Two from the intersection — solid work.",
			"Head over to the market dock. There's a guy named Chad there.",
			"He knows the outer areas better than anyone. Go introduce yourself.",
		],
		"idle": [
			"Chad's waiting at the market dock. Don't hang around here too long.",
		],
	},

	# ── CHAD (market dock NPC, lake intersection) ──────────────────────────
	"chad": {
		"pre": [
			"Market dock's busy. Come back when Tim sends you.",
		],
		"complete": [
			# q7 complete: player talked to Chad. Give q8 (catch 3 fish in Fjord).
			"Tim's recommendation? Alright, I'll give you a shot.",
			"The fjord area north of here has fish you won't find anywhere else.",
			"Catch two of them. Then we'll see about the real challenge.",
		],
		"waiting": [
			"Two fjord fish. The fjord area is north — get moving.",
		],
		"q8_done": [
			# q8 complete: player caught 3 fjord fish, talks to Chad. Give q9 (beat fjord boss).
			"Two fjord fish. Good. There's something bigger out there though.",
			"There are multiple fjord boss fish lurking up there. Take down three of them and come back.",
		],
		"q9_done": [
			# q9 complete: fjord boss caught, talks to Chad. Give q10 (talk to George).
			"Three fjord bosses. You actually did it.",
			"There's more. Head to the small dock — talk to George.",
			"He'll point you toward the mine area.",
		],
		"idle": [
			"George is at the small dock. Go find him.",
		],
	},

	# ── GEORGE (small dock NPC, lake intersection) ─────────────────────────
	"george": {
		"pre": [
			"Not my turn yet. Chad will send you my way eventually.",
		],
		"complete": [
			# q10 complete: player talked to George. Give q11 (catch 3 mine fish).
			"Chad told me about you. You handled the fjord well.",
			"The quarry is different. Dark and loud. The fish there are tough.",
			"Catch two of them and report back.",
		],
		"waiting": [
			"Two fish from the quarry. It's not easy down there.",
		],
		"q11_done": [
			# q11 complete: 3 mine fish caught, talks to George. Give q12 (beat mine boss).
			"Two quarry fish. You're tougher than you look.",
			"There's a boss down in the quarry. Old and mean.",
			"Bring it down. I'll be here.",
		],
		"q12_done": [
			# q12 complete: mine boss caught, talks to George. Give q13 (talk to Bob).
			"The quarry boss. Incredible.",
			"You're ready for the delta. Head there and find Bob — he's at Tower 1 dock.",
			"Good luck. You'll need it.",
		],
		"idle": [
			"Bob is at Tower 1 dock in the delta. Go find him.",
		],
	},

	# ── BOB (Tower 1 dock NPC, delta area) ─────────────────────────────────
	"bob": {
		"pre": [
			"Busy here. Come back when George sends you my way.",
		],
		"complete": [
			# q13 complete: player talked to Bob. Give q14 (catch 3 delta fish).
			"George's fisher. Good — I've been expecting you.",
			"The delta is past here — end of the line, nothing beyond it but open ocean.",
			"Head out there and catch four delta fish first. Show me you belong here.",
		],
		"waiting": [
			"Four delta fish from out there. Keep at it.",
		],
		"q14_done": [
			# q14 complete: 3 delta fish caught, talks to Bob. Give q15 (final boss).
			"Four delta fish. You've come a long way.",
			"There's one more thing. The final boss lurks in the deepest part of the delta.",
			"This is what it's all been leading to. Go end it.",
		],
		"idle": [
			"The delta is waiting. You know what to do.",
		],
	},
}

# ========================================
# INITIALIZATION
# ========================================

func _ready() -> void:
	pass

func register_ui(ui) -> void:
	dialogueUI = ui

# ========================================
# START DIALOGUE
# ========================================

func start_dialogue(npc_id: String) -> void:
	current_npc = npc_id
	_advance_on_end = false

	var npc = dialogue.get(npc_id, null)
	if npc == null:
		push_warning("[DialogueManager] No dialogue data for NPC: %s" % npc_id)
		return

	var q = QuestManager.current_quest_id
	var quest = QuestManager.quests.get(q, null)

	print_debug("[Dialogue] Talking to: %s | current quest: %s | type: %s" % [
		npc_id, q, quest.get("type", "?") if quest else "none"
	])

	var lines: Array = []

	# ── Is this NPC relevant to the current quest? ────────────────────────
	if QuestManager.is_talk_quest_for(npc_id):
		# Current quest is "talk to this NPC" — talking completes it.
		lines = npc.get("complete", [])
		_advance_on_end = true
		print_debug("[Dialogue] Talk quest complete — will advance after lines")

	elif quest != null and quest["type"] in ["catch_in_area", "catch_fish", "final"]:
		# Current quest is a catch quest — check if done.
		# First find which NPC is supposed to receive this quest's turn-in.
		# Turn-in NPCs are the NPC whose "complete" block gives the NEXT quest.
		# We identify the turn-in NPC as the NPC assigned to the *previous* talk quest.
		var turn_in_npc = _get_turn_in_npc_for(q)
		if turn_in_npc == npc_id:
			if QuestManager.is_current_quest_complete():
				# Done — show completion lines and advance.
				lines = _get_completion_lines(npc_id, q)
				_advance_on_end = true
				print_debug("[Dialogue] Catch quest complete — will advance after lines")
			else:
				# Not done yet — show encouragement.
				lines = npc.get("waiting", [])
				var caught = QuestManager.count_area_fish(quest.get("check_area", "")) if quest["type"] == "catch_in_area" else 0
				print_debug("[Dialogue] Catch quest not complete — %d/%d in %s" % [caught, quest.get("goal", 1), quest.get("check_area", quest.get("fish_id", "?"))])
		else:
			# Wrong NPC for this quest.
			lines = npc.get("pre", [])
			print_debug("[Dialogue] Wrong NPC for current quest — showing pre lines")

	else:
		# This NPC's quest chain is in the past or future.
		var npc_quest_idx = _get_last_quest_idx_for(npc_id)
		var current_idx   = QuestManager.QUEST_ORDER.find(q)
		if npc_quest_idx != -1 and current_idx > npc_quest_idx:
			lines = npc.get("idle", [])
			print_debug("[Dialogue] NPC quest chain complete — showing idle")
		else:
			lines = npc.get("pre", [])
			print_debug("[Dialogue] NPC not yet relevant — showing pre")

	if lines.is_empty():
		print_debug("[Dialogue] WARNING: no lines resolved for %s" % npc_id)
		end_dialogue()
		return

	print_debug("[Dialogue] Showing %d lines. First: \"%s\"" % [lines.size(), lines[0]])
	_lines = lines
	_line_idx = 0
	active = true
	if dialogueUI:
		dialogueUI.show_dialogue(lines, npc_id)

# ========================================
# LINE PROGRESSION
# ========================================

func next_line(_npc_id: String) -> void:
	if _lines.is_empty():
		return
	_line_idx += 1
	if _line_idx < _lines.size():
		if is_instance_valid(dialogueUI):
			dialogueUI.show_line(_lines[_line_idx])
		return
	# Reached end of lines.
	if _advance_on_end:
		QuestManager.advance_quest()
		# Emit legacy signal so RipplingWaterSpawners wake up.
		emit_signal("quest_started", QuestManager.current_quest_id)
	end_dialogue()

func end_dialogue() -> void:
	active = false
	current_npc = ""
	_lines = []
	_line_idx = 0
	_advance_on_end = false
	if dialogueUI:
		dialogueUI.hide_dialogue()

# ========================================
# HELPERS
# ========================================

## Returns true if this NPC has something new to say right now.
## Used by npc.gd to show/hide the exclamation indicator.
func has_new_lines(npc_id: String) -> bool:
	var q = QuestManager.current_quest_id
	var quest = QuestManager.quests.get(q, null)

	# Talk quest pointing at this NPC — always has something.
	if QuestManager.is_talk_quest_for(npc_id):
		return true

	# Catch quest — only the turn-in NPC has new lines when complete.
	if quest != null and quest["type"] in ["catch_in_area", "catch_fish", "final"]:
		var turn_in = _get_turn_in_npc_for(q)
		if turn_in == npc_id:
			return QuestManager.is_current_quest_complete()

	# Past quest chain — idle lines.
	var npc_last_idx = _get_last_quest_idx_for(npc_id)
	var current_idx  = QuestManager.QUEST_ORDER.find(q)
	if npc_last_idx != -1 and current_idx > npc_last_idx:
		var npc = dialogue.get(npc_id, {})
		return not npc.get("idle", []).is_empty()

	return false

## For a catch quest, returns the npc_id of the NPC the player should return to.
## This is the NPC from the most recent "talk" quest before this one.
func _get_turn_in_npc_for(quest_id: String) -> String:
	var idx = QuestManager.QUEST_ORDER.find(quest_id)
	if idx <= 0:
		return ""
	# Walk backwards to find the last talk quest
	for i in range(idx - 1, -1, -1):
		var qid = QuestManager.QUEST_ORDER[i]
		var q = QuestManager.quests.get(qid, null)
		if q != null and q["type"] == "talk":
			return q.get("npc", "")
	return ""

## Returns the completion lines for an NPC at the end of a given catch quest.
## Some NPCs handle multiple catch quests (e.g. chad handles q8 and q9),
## so we look up a specific keyed block if it exists, otherwise fall back to "complete".
func _get_completion_lines(npc_id: String, quest_id: String) -> Array:
	var npc = dialogue.get(npc_id, {})
	# Try a quest-specific key first, e.g. "q8_done"
	var specific_key = "%s_done" % quest_id
	if npc.has(specific_key):
		return npc[specific_key]
	return npc.get("complete", [])

## Returns the index in QUEST_ORDER of the last quest this NPC is involved in.
## Used to detect when an NPC's arc is complete and they should show idle lines.
func _get_last_quest_idx_for(npc_id: String) -> int:
	var last := -1
	for i in range(QuestManager.QUEST_ORDER.size()):
		var qid = QuestManager.QUEST_ORDER[i]
		var q = QuestManager.quests.get(qid, null)
		if q == null:
			continue
		if q.get("npc", "") == npc_id:
			last = i
		# Also include catch quests whose turn-in NPC is this NPC
		if q["type"] in ["catch_in_area", "catch_fish"] and _get_turn_in_npc_for(qid) == npc_id:
			last = i
	return last

func get_current_lines() -> Array:
	return _lines
