extends NPC
class_name ShopNPC
## Shop NPC
## Extends NPC with a shop mode that activates once all dialogue lines are exhausted.
## The same "Press E" prompt is reused — context switches from "talk" to "shop".


# ========================================
# EXPORTS
# ========================================

## Item ids to sell. Must match ids in ShopManager.ITEM_CATALOG.
@export var shop_item_ids: Array[String] = [
	"worm_bait",
	"shiny_lure",
	"mystery_bait",
	"rod_tip_upgrade",
	"lucky_hook",
	"fish_almanac",
]

## Header text shown at the top of the shop panel.
@export var shop_title: String = "Shop"

# ========================================
# STATE
# ========================================

var _shop_instance: CanvasLayer = null
var _shop_scene := preload("res://scenes/ui/shops/npc_shop_ui.tscn")

# Whether dialogue has been fully exhausted at least once this session.
# Once true, interact opens the shop instead of restarting dialogue.
var _dialogue_done: bool = false

# ========================================
# OVERRIDE: _process
# ========================================

func _process(delta: float) -> void:
	if not player_in_range:
		prompt_ui.visible = false
		return

	# If the shop is open, suppress all other processing.
	if _shop_instance != null:
		return

	if questPopup.visible:
		_update_indicator()
		return

	# Decide which mode to enter in (dialogue or shop).
	var has_lines := DialogueManager.has_new_lines(npc_id)

	if not DialogueManager.active:
		if has_lines:
			# Dialogue mode — show the standard enter-to-talk prompt.
			_dialogue_done = false
			prompt_ui.visible = true
			DialogueManager.dialogueUI.hide_interaction_prompt()
		else:
			# Shop mode — dialogue exhausted, show shop prompt.
			_dialogue_done = true
			prompt_ui.visible = false
			DialogueManager.dialogueUI.show_interaction_prompt()
	else:
		prompt_ui.visible = false
		indicator.visible = false

	if Input.is_action_just_pressed("ui_accept"):
		get_viewport().set_input_as_handled()

		if DialogueManager.active:
			# Advance or finish dialogue as usual.
			if DialogueManager.dialogueUI.typing:
				DialogueManager.dialogueUI.finish_line()
			else:
				DialogueManager.next_line(npc_id)

		elif has_lines:
			# Start dialogue (first visit or new quest lines).
			DialogueManager.start_dialogue(npc_id)

		elif _dialogue_done:
			# Open shop.
			_open_shop()

# ========================================
# SHOP MANAGEMENT
# ========================================

func _open_shop() -> void:
	if _shop_instance != null:
		return  # Already open.

	DialogueManager.dialogueUI.hide_interaction_prompt()

	_shop_instance = _shop_scene.instantiate()
	_shop_instance.setup(shop_title, shop_item_ids)
	get_tree().root.add_child(_shop_instance)

	# Pause world and capture shop_closed signal.
	get_tree().paused = true
	_shop_instance.shop_closed.connect(_on_shop_closed)

func _on_shop_closed() -> void:
	get_tree().paused = false

	if _shop_instance:
		_shop_instance.queue_free()
		_shop_instance = null

	# Restore the shop prompt so the player can re-open it.
	if player_in_range:
		DialogueManager.dialogueUI.show_interaction_prompt()