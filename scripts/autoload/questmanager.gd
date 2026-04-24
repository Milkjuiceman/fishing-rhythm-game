extends Node
## QuestManager Autoload
## Manages all quest state, progress, and completion for the game.
## Supports two quest types:
##   - Standard: progress updated manually via update_progress()
##   - inventory_check: auto-completes by watching InventoryManager for fish catches
## Author: Tyler Schauermann
## Date of last update: 04/22/2026

signal active_quests_changed(quests)
signal quest_started(quest_id)
signal quest_completed(quest_id)

enum states {
	NOT_STARTED,
	ACTIVE,
	COMPLETED,
	TURNEDIN
}

# ========================================
# QUEST DEFINITIONS
# ========================================
# type "standard"        — progress updated via update_progress()
# type "inventory_check" — auto-watches InventoryManager.fish_caught
#   requires: "check_area" (String) — area name from FishRegistry to count fish from
#             "goal"       (int)    — how many distinct fish from that area must be caught

var quests := {
	# ── Tutorial 01 ─────────────────────────────────────────────
	"tutorial_01": {
		"title": "your first catch",
		"description": "hook a fish in the lake and reel it in!",
		"desc": "catch a fish",
		"turnitin": "go talk to the fisher\non the other side of the lake!",
		"goal": 1,
		"type": "standard",
	},
	# ── Tutorial 02 ─────────────────────────────────────────────
	"tutorial_02": {
		"title": "meet the locals",
		"description": "head to the other side of the lake\nand talk to the fisher there.",
		"desc": "talk to the fisher across the lake",
		"turnitin": "talk to the fisher\nacross the lake!",
		"goal": 1,
		"type": "standard",
	},
	# ── Tutorial 03 ─────────────────────────────────────────────
	"tutorial_03": {
		"title": "three of a kind",
		"description": "catch 3 different fish in the tutorial lake.",
		"desc": "catch 3 different fish",
		"turnitin": "head to the\nnext fishing area!",
		"goal": 3,
		"type": "inventory_check",
		"check_area": "Tutorial Lake",
	},
	# ── Tutorial 04 ─────────────────────────────────────────────
	"tutorial_04": {
		"title": "onward!",
		"description": "make your way to the next fishing area.",
		"desc": "travel to the next area",
		"goal": 1,
		"type": "standard",
	},
}

var quest_states := {}

# ========================================
# INITIALIZATION
# ========================================

func _ready():
	DialogueManager.quest_started.connect(start_quest)
	_register_all_quests()
	# Watch for fish catches to auto-update inventory_check quests
	InventoryManager.fish_caught.connect(_on_fish_caught)

func _register_all_quests():
	for qid in quests.keys():
		quest_states[qid] = {
			"progress": 0,
			"state": states.NOT_STARTED
		}

# ========================================
# QUEST LIFECYCLE
# ========================================

func start_quest(quest_id: String):
	if not quests.has(quest_id):
		print_debug("[QuestManager] Quest not defined:", quest_id)
		return
	var state = quest_states[quest_id]
	if state["state"] == states.NOT_STARTED:
		state["state"] = states.ACTIVE
		print_debug("[QuestManager] Started:", quests[quest_id]["title"])
		emit_signal("quest_started", quest_id)
		emit_signal("active_quests_changed", get_active_quests())
		# If this is an inventory_check quest, run an immediate check in case
		# the player already has qualifying fish from before the quest started.
		if quests[quest_id].get("type", "standard") == "inventory_check":
			_check_inventory_quest(quest_id)

func update_progress(quest_id: String, amount: int):
	if not quest_states.has(quest_id):
		return
	var state = quest_states[quest_id]
	var quest = quests[quest_id]
	if state["state"] != states.ACTIVE:
		return
	state["progress"] += amount
	if state["progress"] >= quest["goal"]:
		state["progress"] = quest["goal"]
		state["state"] = states.COMPLETED
		print_debug("[QuestManager] Completed:", quest["title"])
		emit_signal("quest_completed", quest_id)
	emit_signal("active_quests_changed", get_active_quests())

func turn_in_quest(quest_id: String):
	if not quest_states.has(quest_id):
		return
	var state = quest_states[quest_id]
	if state["state"] == states.COMPLETED:
		state["state"] = states.TURNEDIN
	print_debug("[QuestManager] Turned in:", quests[quest_id]["title"])
	emit_signal("active_quests_changed", get_active_quests())

# ========================================
# INVENTORY_CHECK QUEST LOGIC
# ========================================

## Called whenever a fish is caught. Checks all active inventory_check quests.
func _on_fish_caught(_fish_id: String, _new_count: int) -> void:
	for qid in quests.keys():
		if quests[qid].get("type", "standard") == "inventory_check":
			if quest_states[qid]["state"] == states.ACTIVE:
				_check_inventory_quest(qid)

## Counts distinct fish from the quest's area that the player has caught at least once.
func _check_inventory_quest(quest_id: String) -> void:
	var quest = quests[quest_id]
	var area_name: String = quest.get("check_area", "")
	var goal: int = quest["goal"]

	var distinct_caught := 0
	for area_data in FishRegistry.get_all_areas():
		if area_data["area"] == area_name:
			for fish in area_data["fish"]:
				if InventoryManager.has_caught_fish(fish["fish_id"]):
					distinct_caught += 1

	var state = quest_states[quest_id]
	state["progress"] = distinct_caught
	if distinct_caught >= goal:
		state["progress"] = goal
		state["state"] = states.COMPLETED
		print_debug("[QuestManager] Inventory check completed:", quest["title"])
		emit_signal("quest_completed", quest_id)
	emit_signal("active_quests_changed", get_active_quests())

# ========================================
# QUERY API
# ========================================

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
		if state["state"] in [states.ACTIVE, states.COMPLETED]:
			var ui_description: String
			if state["state"] == states.COMPLETED and quest.has("turnitin"):
				ui_description = " - %s (%d/%d)\n> %s" % [quest["desc"], state["progress"], quest["goal"], quest["turnitin"]]
			else:
				ui_description = "> %s (%d/%d)" % [quest["desc"], state["progress"], quest["goal"]]
			result[qid] = {
				"title": quest["title"],
				"description": quest["description"],
				"desc": ui_description,
				"progress": state["progress"],
				"goal": quest["goal"]
			}
	return result
