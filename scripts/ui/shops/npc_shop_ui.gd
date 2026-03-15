extends CanvasLayer
class_name NpcShopUI
## NPC Shop UI
## CanvasLayer shop panel displayed when the player interacts with a ShopNPC.
## Mirrors the boat_upgrade_store.gd pattern: pauses game, emits shop_closed.

signal shop_closed

# ========================================
# NODE REFERENCES  (matched to scene structure above)
# ========================================

@onready var title_label: Label         = $Panel/VBoxContainer/TitleLabel
@onready var currency_label: Label      = $Panel/VBoxContainer/CurrencyLabel
@onready var item_list: VBoxContainer   = $Panel/VBoxContainer/ItemList
@onready var close_button: Button       = $Panel/VBoxContainer/CloseButton

# ========================================
# STATE
# ========================================

var _item_ids: Array[String] = []
var _feedback_timer: float = 0.0
var _feedback_label: Label = null

const FEEDBACK_DURATION: float = 1.5

# ========================================
# INITIALIZATION
# ========================================

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS   # Works while game is paused.
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	close_button.pressed.connect(_on_close_pressed)

	# Live currency updates (for if another system adds coins mid-session).
	InventoryManager.currency_changed.connect(_refresh_currency)
	_refresh_currency(InventoryManager.get_currency())

## Called by ShopNPC immediately after instantiation.
func setup(shop_title: String, item_ids: Array) -> void:
	_item_ids.clear()
	for id in item_ids:
		_item_ids.append(id as String)

	title_label.text = shop_title
	_refresh_currency(InventoryManager.get_currency())
	_build_item_list()

# ========================================
# BUILD ITEM ROWS
# ========================================

func _build_item_list() -> void:
	# Clear old rows.
	for child in item_list.get_children():
		child.queue_free()

	var catalog_items := ShopManager.get_items_for_ids(_item_ids)

	if catalog_items.is_empty():
		var empty_label := Label.new()
		empty_label.text = "(Nothing for sale)"
		item_list.add_child(empty_label)
		return

	for item_data in catalog_items:
		item_list.add_child(_make_item_row(item_data))

	# Feedback label (hidden until a purchase is attempted).
	_feedback_label = Label.new()
	_feedback_label.name            = "FeedbackLabel"
	_feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_feedback_label.visible         = false
	item_list.add_child(_feedback_label)


func _make_item_row(item_data: Dictionary) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = "Row_" + item_data["id"]

	# Item name + description.
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var name_label := Label.new()
	name_label.text = item_data["display_name"]
	info.add_child(name_label)

	var desc_label := Label.new()
	desc_label.text              = item_data["description"]
	desc_label.add_theme_font_size_override("font_size", 11)
	desc_label.modulate          = Color(0.75, 0.75, 0.75)
	desc_label.autowrap_mode     = TextServer.AUTOWRAP_WORD_SMART
	info.add_child(desc_label)

	# Owned count (updates on purchase via signal).
	var owned_label := Label.new()
	owned_label.name             = "Owned"
	owned_label.text             = "x%d" % InventoryManager.get_item_count(item_data["id"])
	owned_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	owned_label.custom_minimum_size = Vector2(30, 0)

	# Price + buy button.
	var price_label := Label.new()
	price_label.text                   = "%d 🪙" % item_data["price"]
	price_label.vertical_alignment     = VERTICAL_ALIGNMENT_CENTER
	price_label.custom_minimum_size    = Vector2(60, 0)

	var buy_button := Button.new()
	buy_button.text = "Buy"
	buy_button.pressed.connect(_on_buy_pressed.bind(item_data["id"], owned_label))

	# Disable buy if max_stack already reached.
	_update_buy_button(buy_button, item_data)

	row.add_child(info)
	row.add_child(owned_label)
	row.add_child(price_label)
	row.add_child(buy_button)

	# Keep owned count and buy button in sync after purchases.
	InventoryManager.item_changed.connect(
		func(changed_id: String, new_count: int) -> void:
			if changed_id != item_data["id"]:
				return
			owned_label.text = "x%d" % new_count
			_update_buy_button(buy_button, item_data)
	)

	return row


func _update_buy_button(button: Button, item_data: Dictionary) -> void:
	if item_data["max_stack"] > 0:
		var owned := InventoryManager.get_item_count(item_data["id"])
		button.disabled = owned >= item_data["max_stack"]


# ========================================
# PROCESS (feedback timer)
# ========================================

func _process(delta: float) -> void:
	if _feedback_timer > 0.0:
		_feedback_timer -= delta
		if _feedback_timer <= 0.0 and _feedback_label:
			_feedback_label.visible = false

# ========================================
# BUTTON HANDLERS
# ========================================

func _on_buy_pressed(item_id: String, owned_label: Label) -> void:
	var success := ShopManager.try_purchase(item_id)

	if success:
		_show_feedback("Purchased!", Color(0.3, 1.0, 0.4))
	else:
		# Distinguish the two common failure reasons.
		var item := ShopManager.get_item(item_id)
		if not item.is_empty() and InventoryManager.get_item_count(item_id) >= item["max_stack"]:
			_show_feedback("Already owned!", Color(1.0, 0.8, 0.2))
		else:
			_show_feedback("Not enough coins!", Color(1.0, 0.3, 0.3))


func _on_close_pressed() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	shop_closed.emit()

# ========================================
# HELPERS
# ========================================

func _refresh_currency(amount: int) -> void:
	if currency_label:
		currency_label.text = "🪙 %d coins" % amount


func _show_feedback(message: String, color: Color) -> void:
	if not _feedback_label:
		return
	_feedback_label.text    = message
	_feedback_label.modulate = color
	_feedback_label.visible  = true
	_feedback_timer = FEEDBACK_DURATION