class_name Inventory
extends Resource

var currency: int = 0
@export var items: Dictionary = {} # key: item_id_with_rarity, value = count

signal currency_changed(new_amount)
signal inventory_changed()

func add_currency(amount: int) -> void:
	currency += amount
	emit_signal("currency_changed", currency)
	
func add_item(item_id: String, rarity: String = "", amount: int = 1) -> void:
	print("Inventory instance ID:", self)
	var key = item_id
	if rarity != "":
		key += "_" + rarity
	if not items.has(key):
		items[key] = 0
	items[key] += amount
	emit_signal("inventory_changed")
	
func get_item_count(item_id: String, rarity: String = "") -> int:
	var key = item_id
	if rarity != "":
		key += "_" + rarity
	return items.get(key, 0)
