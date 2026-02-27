extends Node
class_name InventoryManager

signal item_changed(item_id: String, rarity: String, new_amount: int)
var inventory: Inventory

func _ready() -> void:
	inventory = Inventory.new()
	inventory.item_changed.connect(_on_item_changed)

func _on_item_changed(item_id: String, rarity: String, new_amount: int) -> void:
	emit_signal("item_changed", item_id, rarity, new_amount)
