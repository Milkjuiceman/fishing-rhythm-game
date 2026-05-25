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
		"title": "meet gramps",
		"description": "head to the dock and talk to Gramps.",
		"hint": "talk to Gramps at the dock",
		"type": "talk",
		"npc": "gramps",
	},
	"q2": {
		"title": "first catch",
		"description": "catch 1 fish in the tutorial lake.",
		"hint": "catch a fish",
		"type": "catch_in_area",
		"check_area": "Tutorial Lake",
		"goal": 1,
	},
	"q3": {
		"title": "go find paul",
		"description": "head across the lake and talk to Paul.",
		"hint": "talk to Paul across the lake",
		"type": "talk",
		"npc": "paul",
	},
	"q4": {
		"title": "three of a kind",
		"description": "catch 3 different fish in the tutorial lake.",
		"hint": "catch 3 different fish in the tutorial lake",
		"type": "catch_in_area",
		"check_area": "Tutorial Lake",
		"goal": 3,
	},
	"q5": {
		"title": "head to the intersection",
		"description": "travel to the lake intersection and talk to Tim.",
		"hint": "talk to Tim at the intersection",
		"type": "talk",
		"npc": "tim",
	},
	# ── Intersection Area ────────────────────────────────────────────────
	"q6": {
		"title": "intersection catch",
		"description": "catch 2 fish in the intersection area.",
		"hint": "catch 2 fish in the intersection area",
		"type": "catch_in_area",
		"check_area": "Intersection Area",
		"goal": 2,
	},
	"q7": {
		"title": "meet chad",
		"description": "head to the market and talk to Chad.",
		"hint": "talk to Chad at the market dock",
		"type": "talk",
		"npc": "chad",
	},
	"q8": {
		"title": "fjord fishing",
		"description": "catch 2 fish in the fjord area.",
		"hint": "catch 2 fish in the fjord area",
		"type": "catch_in_area",
		"check_area": "Fjord Area",
		"goal": 2,
	},
	"q9": {
		"title": "fjord bosses",
		"description": "defeat 3 boss fish in the fjord area.",
		"hint": "defeat 3 fjord boss fish (0/3)",
		"type": "catch_in_area",
		"check_area": "Fjord Bosses",
		"goal": 3,
	},
	"q10": {
		"title": "meet george",
		"description": "talk to George at the small dock.",
		"hint": "talk to George at the small dock",
		"type": "talk",
		"npc": "george",
	},
	"q11": {
		"title": "quarry fishing",
		"description": "catch 2 fish in the quarry area.",
		"hint": "catch 2 fish in the quarry area",
		"type": "catch_in_area",
		"check_area": "Quarry Area",
		"goal": 2,
	},
	"q12": {
		"title": "quarry boss",
		"description": "defeat the boss fish in the quarry area.",
		"hint": "defeat the quarry boss fish",
		"type": "catch_in_area",
		"check_area": "Quarry Bosses",
		"goal": 1,
	},
	"q13": {
		"title": "find bob",
		"description": "head to the tower dock in the intersection and talk to Bob.",
		"hint": "talk to Bob at the tower dock",
		"type": "talk",
		"npc": "bob",
	},
	# ── Delta Area ───────────────────────────────────────────────────────
	"q14": {
		"title": "delta fishing",
		"description": "catch 4 fish in the delta area.",
		"hint": "catch 4 fish in the delta area",
		"type": "catch_in_area",
		"check_area": "Delta Area",
		"goal": 4,
	},
	"q15": {
		"title": "final boss",
		"description": "defeat the final boss in the delta.",
		"hint": "defeat the final boss",
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
