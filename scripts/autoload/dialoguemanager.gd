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
			"Hold on — you haven't even gotten your feet wet yet. Come back once you've had a look around.",
		],
		"complete": [
			# q1 complete: player talked to Gramps. Give q2 (catch 1 fish).
			"There you are. Was starting to think you'd gotten lost on a lake you can see across.",
			"She's not much, your boat. But she floats, and that's half the job done.",
			"Look for the ripples out there. Fish always give themselves away if you watch long enough.",
			"Hook me something. Anything. Let's see if you've got the patience for this.",
		],
		"waiting": [
			# q2 active, player back before catching anything
			"Nothing yet? The fish aren't going to climb in on their own.",
			"Watch the surface. When the water moves wrong — that's your moment.",
		],
		"q2_done": [
			# q2 complete: player caught 1 fish, talks to Gramps. Give q3 (talk to Paul).
			"Well. Look at that.",
			"I've seen plenty of first catches. Most people freeze up, miss their shot. You didn't.",
			"There's a man on the far side of the lake. Name's Paul. Been fishing here longer than I have.",
			"Go introduce yourself. Tell him I sent you — he'll give you the time of day.",
		],
		"idle": [
			"Paul's over on the far bank. Don't keep him waiting on my account.",
		],
	},

	# ── PAUL (lake NPC, tutorial lake) ────────────────────────────────────
	"paul": {
		"pre": [
			"Don't mind me. I'm in the middle of something. Go talk to the fellow at the dock first.",
		],
		"complete": [
			# q3 complete: player talked to Paul. Give q4 (catch 3 fish).
			"Gramps sent you over? Good. He doesn't do that for just anyone.",
			"This lake's got more variety than it looks. Three different fish hiding in it — each one in its own spot.",
			"Most people never find all three. Too impatient.",
			"Catch one of each. Then come back. I want to see what you're working with.",
		],
		"waiting": [
			"Three different species. Not three of the same one.",
			"Each ripple spot is different. Keep moving until you've found them all.",
		],
		"q4_done": [
			# q4 complete: player caught 3 fish, talks to Paul. Give q5 (talk to Tim).
			"All three. You actually got all three.",
			"I'll be honest — I didn't expect that on your first day.",
			"There's more water past this lake. A lot more. Head to the intersection — it's where everything branches off.",
			"Find Tim at the main dock there. Tell him you came from the home lake. He'll know what that means.",
		],
		"idle": [
			"Tim's at the intersection dock. He runs the place — hard to miss.",
		],
	},

	# ── TIM (main dock NPC, lake intersection) ─────────────────────────────
	"tim": {
		"pre": [
			"Busy dock. Come back once Paul's had a look at you.",
		],
		"complete": [
			# q5 complete: player talked to Tim. Give q6 (catch 2 fish in intersection).
			"Home lake, huh. Paul doesn't send many people this way.",
			"The intersection is where the water gets complicated. Currents from four directions — the fish here behave differently.",
			"Before you go any further, prove you can handle it. Two fish from this stretch.",
			"Don't rush. The intersection rewards patience more than speed.",
		],
		"waiting": [
			"Two from the intersection waters. You're close.",
			"The fish here run deeper than back home. Give it time.",
		],
		"q6_done": [
			# q6 complete: player caught 2 intersection fish, talks to Tim. Give q7 (talk to Chad).
			"Two intersection fish. You adjusted fast — most people struggle with the currents at first.",
			"There's a man at the market dock named Chad. Runs supplies to the outer areas.",
			"He knows the fjord better than anyone who'll admit it. Go have a word.",
			"Tell him Tim cleared you. He's particular about who he talks to.",
		],
		"idle": [
			"Chad's at the market dock. He's not the friendliest but he's straight with people he respects.",
		],
	},

	# ── CHAD (market dock NPC, lake intersection) ──────────────────────────
	"chad": {
		"pre": [
			"I don't talk shop with strangers. Come back when Tim vouches for you.",
		],
		"complete": [
			# q7 complete: player talked to Chad. Give q8 (catch 2 fish in Fjord).
			"Tim cleared you. Alright.",
			"The fjord's north of here. Cold water, strange currents, fish you won't find anywhere else.",
			"I've been running supplies up there for six years. Lately the hauls have been... off.",
			"Catch two fjord fish. I want to know if you notice what I've been noticing.",
		],
		"waiting": [
			"Two from the fjord. Take your time — rushing up there never ends well.",
		],
		"q8_done": [
			# q8 complete: player caught 2 fjord fish, talks to Chad. Give q9 (beat fjord bosses).
			"Two fjord fish. Did anything seem strange to you up there?",
			"The ones I've been seeing lately are bigger. Faster. Not right for the season.",
			"There are things in the deep part of the fjord that weren't there two years ago.",
			"Three of them. Big ones. Take them down and come back. I need to know if they're what I think they are.",
		],
		"q9_done": [
			# q9 complete: fjord bosses caught, talks to Chad. Give q10 (talk to George).
			"Three fjord bosses. So it's not just the fjord.",
			"I've heard the same thing from the quarry side. There's a man named George — works the docks near the quarry entrance.",
			"Quiet guy. Doesn't say much, but he's been watching the water longer than most.",
			"Go find him at the small dock. Tell him what you found in the fjord.",
		],
		"idle": [
			"George is at the small dock near the quarry. He's expecting someone — might as well be you.",
		],
	},

	# ── GEORGE (small dock NPC, lake intersection) ─────────────────────────
	"george": {
		"pre": [
			"Not yet. Chad needs to send you first.",
		],
		"complete": [
			# q10 complete: player talked to George. Give q11 (catch 2 quarry fish).
			"The fjord. Yeah. I've been watching the quarry side.",
			"It's the same thing. Fish that don't belong there. Too big, too aggressive.",
			"The quarry water is dark and loud — machines running day and night nearby. The fish learned to be mean to survive it.",
			"Get two of them. I want to compare what you pull out with what I've been logging.",
		],
		"waiting": [
			"Two quarry fish. It's rough water down there. Take it steady.",
		],
		"q11_done": [
			# q11 complete: 2 quarry fish caught, talks to George. Give q12 (beat quarry boss).
			"Those match what I've been seeing. Something's pushing them up from deeper water.",
			"There's one in particular that's been down there a long time. Old. The quarry workers call it the Shelf Boss.",
			"Nobody's touched it. I don't think anyone's tried.",
			"You've handled the fjord bosses. See if you can bring this one up.",
		],
		"q12_done": [
			# q12 complete: quarry boss caught, talks to George. Give q13 (talk to Bob).
			"The Shelf Boss. I didn't think that was possible.",
			"Whatever's causing this — it's coming from further out. The delta.",
			"There's a man named Bob at Tower 1 dock, out in the delta. He's been living out there alone for years.",
			"If anyone knows what's happening at the source, it's him. Go find him.",
		],
		"idle": [
			"Bob's at Tower 1 in the delta. He doesn't come in much, so you'll have to go to him.",
		],
	},

	# ── BOB (Tower 1 dock NPC, delta area) ─────────────────────────────────
	"bob": {
		"pre": [
			"I'm not receiving visitors. Come back when George sends you.",
		],
		"complete": [
			# q13 complete: player talked to Bob. Give q14 (catch 4 delta fish).
			"George's fisher. Took you long enough.",
			"I've been watching the delta for eleven years. What's happening here isn't natural.",
			"The deep current changed about three years back. Something down there is wrong — has been wrong.",
			"Before I tell you what I know, I need to see what you're made of. Four delta fish.",
			"Not the ones near the surface. The real ones. You'll know them when you find them.",
		],
		"waiting": [
			"Four delta fish. The real ones.",
			"Don't come back until you've got four. I mean it.",
		],
		"q14_done": [
			# q14 complete: 4 delta fish caught, talks to Bob. Give q15 (final boss).
			"Four. And you made it back.",
			"You've seen it by now. The water out there isn't right. The fish aren't right.",
			"There's something at the bottom of the delta. I've been watching its wake for three years.",
			"I don't know what it is. I don't think it matters what it is.",
			"What matters is that it ends. Go finish this.",
		],
		"idle": [
			"The deep delta. You know what's down there. Go end it.",
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
			print_debug("[Dialogue] NPC not yet relevant — showing pre lines")

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
