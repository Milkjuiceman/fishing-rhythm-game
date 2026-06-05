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
			"Whoa there, youngster. You haven't even gotten your feet wet yet. Go have a look around first.",
		],
		"complete": [
			# q1 complete: player talked to Gramps. Give q2 (catch 1 fish).
			"Oh good, you found me. I was starting to wonder.",
			"So you want to catch the largest fish in the land, huh? Ha. I love the ambition.",
			"Alright, but you gotta start somewhere. See those ripples out on the water? Fish can't help giving themselves away.",
			"Go catch a fish. Come back and show me when you've caught one.",
		],
		"waiting": [
			# q2 active, player back before catching anything
			"Not yet, youngster. The fish aren't gonna jump in the boat for you.",
			"Keep your eyes on the water. When something moves wrong out there, that's your shot.",
		],
		"q2_done": [
			# q2 complete: player caught 1 fish, talks to Gramps. Give q3 (talk to Paul).
			"Hey, would you look at that. You actually did it.",
			"Most folks freeze up on their first catch. You didn't. That's a good sign.",
			"There's a fella named Paul on the far side of the lake. Go introduce yourself and tell him I sent you.",
			"Oh, and if you want to see your current objective, press Q at any time to check your quests.",
		],
		"idle": [
			"Paul's over on the far bank, youngster.",
		],
	},

	# ── PAUL (lake NPC, tutorial lake) ────────────────────────────────────
	"paul": {
		"pre": [
			"Sorry, not a great time. Go check in with Gramps first.",
		],
		"complete": [
			# q3 complete: player talked to Paul. Give q4 (catch 3 fish).
			"Gramps sent you? Alright, then.",
			"There are 4 fish in this lake. Most people never find all of them — they get impatient.",
			"I want you to catch three different fish and come back. You can check how many you've got by pressing I for your inventory.",
		],
		"waiting": [
			"Three fish total. Don't just catch the same one three times.",
			"Move around the lake. Each spot's got something different if you're patient enough.",
		],
		"q4_done": [
			# q4 complete: player caught 3 fish, talks to Paul. Give q5 (talk to Tim).
			"All three. Huh. I genuinely didn't expect that today.",
			"There's a lot more water past this lake — you should go check it out.",
			"Head to the intersection lake and find a guy named Tim at the main dock. Tell him I sent you.",
		],
		"idle": [
			"Tim's running the intersection dock. You can't really miss him.",
		],
	},

	# ── TIM (main dock NPC, lake intersection) ─────────────────────────────
	"tim": {
		"pre": [
			"It's a busy dock. Come back once Paul's had a look at you.",
		],
		"complete": [
			# q5 complete: player talked to Tim. Give q6 (catch 2 fish in intersection).
			"Paul sent you? Well then you must be something pretty special.",
			"I'll be straight with you — I hold the record for the largest fish ever caught around here. Have for years now.",
			"You want to beat that? You've got a long way to go. But I can help point you in the right direction.",
			"First, show me you can fish here. Catch me two fish from the intersection area.",
		],
		"waiting": [
			"Still need two from the intersection. Take your time.",
			"The fish here run deeper than you're used to. Give it a minute.",
		],
		"q6_done": [
			# q6 complete: player caught 2 intersection fish, talks to Tim. Give q7 (talk to Chad).
			"Nice job! Most people don't adapt that fast.",
			"There's a guy named Chad over at the market dock. Runs supplies out to the fjord.",
			"He knows the fjord better than just about anyone, though he won't admit it.",
			"Tell him I cleared you. He's picky about who he talks to.",
		],
		"idle": [
			"Chad's at the market dock. He's gruff but fair — just tell him Tim sent you.",
		],
	},

	# ── CHAD (market dock NPC, lake intersection) ──────────────────────────
	"chad": {
		"pre": [
			"I don't really talk to strangers. Come back when Tim vouches for you.",
		],
		"complete": [
			# q7 complete: player talked to Chad. Give q8 (catch 2 fish in Fjord).
			"Tim cleared you. Fine.",
			"Look, I've got a problem and I'm not sure you're the right person for it. But let's see.",
			"The fjord's upstream — cold water, weird currents. I've been running supplies up there for years.",
			"Go catch two fish up there and come back. I want to know if you notice anything off.",
		],
		"waiting": [
			"Two from the fjord. Don't rush it up there — the place bites back.",
		],
		"q8_done": [
			# q8 complete: player caught 2 fjord fish, talks to Chad. Give q9 (beat fjord bosses).
			"Two fjord fish. Did anything seem weird to you up there?",
			"There are things living in the deep part of the fjord that weren't there before. Big ones.",
			"Boss fish, you'll know them when you see them. They're way bigger than anything regular. Approach one to take it on.",
			"I need you to go deal with three of them. Then come back and tell me what you saw.",
		],
		"q9_done": [
			# q9 complete: fjord bosses caught, talks to Chad. Give q10 (talk to George).
			"Three fjord bosses. Okay. You've proved your worth — I'll admit I had my doubts.",
			"There's a quiet guy named George over at the small dock near the quarry. He's been watching that water for a long time.",
			"Go find him and tell him what you ran into up in the fjord. I think he'll want to hear it.",
		],
		"idle": [
			"George is at the small dock near the quarry. He's expecting someone — might as well be you.",
		],
	},

	# ── GEORGE (small dock NPC, lake intersection) ─────────────────────────
	"george": {
		"pre": [
			"Not yet. Chad needs to be the one to send you.",
		],
		"complete": [
			# q10 complete: player talked to George. Give q11 (catch 2 quarry fish).
			"Honestly? I'm pretty impressed with what you've done so far. Not many people make it this far.",
			"The mine area's got its own thing going on. Loud, dark, rough water. The fish that live there are mean.",
			"Catch two of them for me. I want to get a look at what's coming out of there.",
		],
		"waiting": [
			"Two from the mine. It's rough water — take it slow.",
		],
		"q11_done": [
			# q11 complete: 2 quarry fish caught, talks to George. Give q12 (beat quarry boss).
			"Good. Those match what I've been seeing.",
			"There's one more down there — been sitting in the deep part of the mine for a long time. Bigger than the rest.",
			"Take it down and come back. Then I'll tell you where to go next.",
		],
		"q12_done": [
			# q12 complete: quarry boss caught, talks to George. Give q13 (talk to Bob).
			"You got the mine boss fish. Didn't think that was actually possible.",
			"There's an orangutan named Bob. He lives near the market dock.",
			"If anyone knows where the largest fish in the land is hiding, it's him. Go find him.",
		],
		"idle": [
			"Bob's near the market dock. You'll have to go to him.",
		],
	},

	# ── BOB (Tower 1 dock NPC, delta area) ─────────────────────────────────
	"bob": {
		"pre": [
			"Not taking visitors. Come back when George sends you.",
		],
		"complete": [
			# q13 complete: player talked to Bob. Give q14 (catch 3 delta fish).
			"George's fisher. Alright, you made it out here.",
			"Yeah, I know where the largest fish in the land is. But I'm not just gonna tell you.",
			"Catch three fish in the delta area downstream first. Then we'll talk.",
		],
		"waiting": [
			"Three delta fish. I'm not budging until you've got them.",
			"Take your time. The delta doesn't reward people who rush.",
		],
		"q14_done": [
			# q14 complete: 3 delta fish caught, talks to Bob. Give q15 (final boss).
			"Three fish. Nice job.",
			"Alright. The largest fish in the land — it's at the far end of the delta.",
			"Head out there. Tim said he'd be waiting for you when you get close.",
		],
		"idle": [
			"The far end of the delta. You know where to go.",
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
