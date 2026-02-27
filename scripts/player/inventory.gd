class_name Inventory
extends Resource

var currency: int = 0
@export var items: Dictionary = {} # key: item_id_with_rarity, value = count

signal currency_changed(new_amount)
signal item_changed(item_id, rarity, new_amount)

func add_currency(amount: int) -> void:
	currency += amount
	emit_signal("currency_changed", currency)
	
func add_item(item_id: String, rarity: String = "", amount: int = 1) -> void:
	print("Inventory instance ID:", self)
	var key = _make_key(item_id, rarity)
	if not items.has(key):
		items[key] = 0
	items[key] += amount
	if items[key] <= 0:
		items.erase(key)
		emit_signal("item_changed", item_id, rarity, 0)
	else:
		emit_signal("item_changed", item_id, rarity, items[key])

func remove_item(item_id: String, rarity: String = "", amount: int = 1) -> void:
	add_item(item_id, rarity, -amount)
	
func get_item_count(item_id: String, rarity: String = "") -> int:
	var key = _make_key(item_id, rarity)
	return items.get(key, 0)

func has_item(item_id: String, rarity: String = "", required_amount: int = 1 ) -> bool:
	return get_item_count(item_id, rarity) >= required_amount

func _make_key(item_id: String, rarity: String) -> String:
	if rarity == "":
		return item_id
	return "%s_%s" % [item_id, rarity]
