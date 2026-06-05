extends Node
## QuestManager Autoload
## Single-quest linear progression system.
## Only one quest is active at a time. Quests advance via advance_quest().
## Fish checks are done inline by DialogueManager on NPC interaction.
## Author: Tyler Schauermann
## Date of last update: 05/23/2026

signal quest_advanced(new_quest_id: String)
signal quest_started(quest_id: String)  # compatibility with RipplingWaterSpawner and GameStateManager
signal active_quests_changed(quests)

# ========================================
# QUEST CHAIN
# ========================================
# "type" controls how completion is checked:
#   "talk"           — completed by talking to the right NPC
#   "catch_in_area"  — player must have `goal` distinct fish from `check_area`
#   "catch_fish"     — player must have caught a specific fish_id (boss fish)
#   "final"          — ends the game

const QUEST_ORDER: Array = [
	"q1","q2","q3","q4","q5",
	"q6","q7","q8","q9","q10",
	"q11","q12","q13","q14","q15"
]

var quests: Dictionary = {
	# ── Tutorial Area ────────────────────────────────────────────────────
	"q1": {
		"title": "Old Gramps",
		"description": "Go talk to Gramps at the dock.",
		"hint": "Talk to Gramps at the dock.",
		"type": "talk",
		"npc": "gramps",
	},
	"q2": {
		"title": "First Catch",
		"description": "Catch 1 fish in the home lake.",
		"hint": "Catch 1 fish in the home lake.",
		"type": "catch_in_area",
		"check_area": "Tutorial Lake",
		"goal": 1,
	},
	"q3": {
		"title": "The Far Bank",
		"description": "Go talk to Paul across the lake.",
		"hint": "Talk to Paul across the lake.",
		"type": "talk",
		"npc": "paul",
	},
	"q4": {
		"title": "Three Kinds",
		"description": "Catch 3 different fish in the home lake.",
		"hint": "Catch 3 different fish in the home lake.",
		"type": "catch_in_area",
		"check_area": "Tutorial Lake",
		"goal": 3,
	},
	"q5": {
		"title": "The Intersection",
		"description": "Go talk to Tim at the intersection dock.",
		"hint": "Talk to Tim at the intersection dock.",
		"type": "talk",
		"npc": "tim",
	},
	# ── Intersection Area ────────────────────────────────────────────────
	"q6": {
		"title": "Crosswater",
		"description": "Catch 2 fish in the intersection area.",
		"hint": "Catch 2 fish in the intersection area.",
		"type": "catch_in_area",
		"check_area": "Intersection Area",
		"goal": 2,
	},
	"q7": {
		"title": "The Supplier",
		"description": "Go talk to Chad at the market dock.",
		"hint": "Talk to Chad at the market dock.",
		"type": "talk",
		"npc": "chad",
	},
	"q8": {
		"title": "Something's Off",
		"description": "Catch 2 fish in the fjord area.",
		"hint": "Catch 2 fish in the fjord area.",
		"type": "catch_in_area",
		"check_area": "Fjord Area",
		"goal": 2,
	},
	"q9": {
		"title": "The Big Ones",
		"description": "Defeat 3 boss fish in the fjord.",
		"hint": "Defeat 3 boss fish in the fjord.",
		"type": "catch_in_area",
		"check_area": "Fjord Bosses",
		"goal": 3,
	},
	"q10": {
		"title": "George",
		"description": "Go talk to George at the small dock.",
		"hint": "Talk to George at the small dock.",
		"type": "talk",
		"npc": "george",
	},
	"q11": {
		"title": "Mine Water",
		"description": "Catch 2 fish in the mine area.",
		"hint": "Catch 2 fish in the mine area.",
		"type": "catch_in_area",
		"check_area": "Quarry Area",
		"goal": 2,
	},
	"q12": {
		"title": "The Mine Boss",
		"description": "Defeat the boss fish in the mine area.",
		"hint": "Defeat the boss fish in the mine area.",
		"type": "catch_in_area",
		"check_area": "Quarry Bosses",
		"goal": 1,
	},
	"q13": {
		"title": "Find Bob",
		"description": "Go talk to Bob near the market dock.",
		"hint": "Talk to Bob near the market dock.",
		"type": "talk",
		"npc": "bob",
	},
	# ── Delta Area ───────────────────────────────────────────────────────
	"q14": {
		"title": "Delta Fishing",
		"description": "Catch 3 fish in the delta area.",
		"hint": "Catch 3 fish in the delta area.",
		"type": "catch_in_area",
		"check_area": "Delta Area",
		"goal": 3,
	},
	"q15": {
		"title": "End of the Line",
		"description": "Defeat the final boss at the end of the delta.",
		"hint": "Defeat the final boss at the end of the delta.",
		"type": "catch_in_area",
		"check_area": "Delta Bosses",
		"goal": 1,
	},
}

# ========================================
# STATE
# ========================================

var current_quest_id: String = "q1"

# ========================================
# INITIALIZATION
# ========================================

func _ready() -> void:
	print_debug("[QuestManager] Game started. First quest: %s" % current_quest_id)
	emit_signal("active_quests_changed", get_active_quests())

# ========================================
# SAVE / LOAD
# ========================================

func load_from_save(quest_id: String) -> void:
	if quest_id != "" and QUEST_ORDER.has(quest_id):
		current_quest_id = quest_id
	else:
		push_warning("[QuestManager] Invalid quest_id in save data: '%s', keeping default" % quest_id)
	emit_signal("active_quests_changed", get_active_quests())

# ========================================
# QUEST ADVANCEMENT
# ========================================

## Moves to the next quest. Called by DialogueManager at the end of a conversation.
func advance_quest() -> void:
	var idx = QUEST_ORDER.find(current_quest_id)
	if idx == -1:
		push_warning("[QuestManager] current_quest_id '%s' not in QUEST_ORDER" % current_quest_id)
		return
	if idx + 1 >= QUEST_ORDER.size():
		print_debug("[QuestManager] All quests complete!")
		return
	var old = current_quest_id
	current_quest_id = QUEST_ORDER[idx + 1]
	print_debug("[QuestManager] Advanced: %s -> %s" % [old, current_quest_id])
	emit_signal("quest_advanced", current_quest_id)
	emit_signal("quest_started", current_quest_id)  # compatibility shim
	emit_signal("active_quests_changed", get_active_quests())

# ========================================
# COMPLETION CHECKS
# ========================================

## Returns how many distinct fish from `area_name` the player has caught.
func count_area_fish(area_name: String) -> int:
	var count := 0
	for area in FishRegistry.get_all_areas():
		if area["area"] == area_name:
			for fish in area["fish"]:
				if InventoryManager.has_caught_fish(fish["fish_id"]):
					count += 1
	return count

## Returns true if the current catch/boss quest condition is met.
func is_current_quest_complete() -> bool:
	var quest = quests.get(current_quest_id, null)
	if quest == null:
		return false
	match quest["type"]:
		"catch_in_area":
			return count_area_fish(quest["check_area"]) >= quest["goal"]
		"catch_fish", "final":
			return InventoryManager.has_caught_fish(quest.get("fish_id", ""))
	return false

## For "talk" quests: returns true if `npc_id` is the NPC this quest wants.
func is_talk_quest_for(npc_id: String) -> bool:
	var quest = quests.get(current_quest_id, null)
	if quest == null:
		return false
	return quest["type"] == "talk" and quest.get("npc", "") == npc_id

# ========================================
# UI DATA
# ========================================

func get_active_quests() -> Dictionary:
	var quest = quests.get(current_quest_id, null)
	if quest == null:
		return {}
	var progress_text: String
	match quest["type"]:
		"catch_in_area":
			var caught = count_area_fish(quest["check_area"])
			progress_text = "%s (%d/%d)" % [quest["hint"], caught, quest["goal"]]
		"catch_fish", "final":
			var done = "done" if InventoryManager.has_caught_fish(quest.get("fish_id", "")) else "in progress"
			progress_text = "%s — %s" % [quest["hint"], done]
		_:
			progress_text = quest["hint"]
	return {
		current_quest_id: {
			"title": quest["title"],
			"description": quest["description"],
			"desc": progress_text,
		}
	}


# ========================================
# LEGACY SHIMS
# ========================================
## get_quest() — called by assignment_popup_ui and npc.gd
## Returns a lightweight object with .title and .description
func get_quest(quest_id: String) -> Dictionary:
	var q = quests.get(quest_id, null)
	if q == null:
		return {}
	return {
		"title": q.get("title", ""),
		"description": q.get("description", ""),
		"hint": q.get("hint", ""),
	}

# ========================================
# LEGACY SHIM (get_quest_state)
# ========================================
## Older code (rippling water spawners) calls get_quest_state(quest_id).
## We remap this: a quest is "active or past" if current_quest_id is at or beyond it.

enum states { NOT_STARTED = 0, ACTIVE = 1, COMPLETED = 2, TURNEDIN = 3 }

func get_quest_state(quest_id: String) -> int:
	var current_idx = QUEST_ORDER.find(current_quest_id)
	var check_idx   = QUEST_ORDER.find(quest_id)
	if check_idx == -1:
		return states.NOT_STARTED
	if check_idx < current_idx:
		return states.TURNEDIN
	if check_idx == current_idx:
		return states.ACTIVE
	return states.NOT_STARTED
