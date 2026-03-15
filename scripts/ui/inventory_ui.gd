extends CanvasLayer
class_name inventory_ui
## Inventory UI
## Displays the player's held items and current coin balance.
## Toggle with the inventory_toggle action (default: I).

@onready var panel: Panel                   = $Panel
@onready var currency_label: Label          = $Panel/VBoxContainer/CurrencyLabel
@onready var items_container: VBoxContainer = $Panel/VBoxContainer/VBoxContainer

func _ready() -> void:
	hide()
	InventoryManager.inventory_changed.connect(_refresh_items)
	InventoryManager.currency_changed.connect(_refresh_currency)
	_refresh_items(InventoryManager.items)
	_refresh_currency(InventoryManager.get_currency())

func toggle() -> void:
	if is_visible():
		hide()
	else:
		show()

func _refresh_items(items: Dictionary) -> void:
	for child in items_container.get_children():
		child.queue_free()
		
	for key in items.keys():
		var label := Label.new()
		label.text = "%s x %d" % [key, items[key]]
		items_container.add_child(label)

func _refresh_currency(amount: int) -> void:
	if currency_label:
		currency_label.text = "🪙 %d coins" % amount