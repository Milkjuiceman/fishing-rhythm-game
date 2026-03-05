extends Node
# global autoloader name is ManageInventory

signal inventory_changed(items: Dictionary)
signal currency_changed(new_amount: int)
signal item_changed(item_id: String, new_amount: int)

var items: Dictionary = {}
var currency: int

func load_from_save(data: Dictionary) -> void:
	items = data.duplicate(true)
	inventory_changed.emit(items)

func add_item(item_id: String, rarity: String = "", amount: int = 1) -> void:
	var key = _make_key(item_id, rarity)
	if not items.has(key):
		items[key] = 0
	items[key] += amount
	if items[key] <= 0:
		items.erase(key)
		emit_signal("item_changed", item_id, 0)
	else:
		emit_signal("item_changed", item_id, amount)
	inventory_changed.emit(items)
	
func remove_item(item_id: String, rarity: String = "", amount: int = 1) -> void:
	add_item(item_id, rarity, -amount)
	
func has_item(item_id: String, rarity: String = "", required_amount: int = 1 ) -> bool:
	return get_item_count(item_id, rarity) >= required_amount

func get_item_count(item_id: String, rarity: String = "") -> int:
	var key = _make_key(item_id, rarity)
	return items.get(key, 0)
	
	
func add_currency(amount: int) -> void:
	currency += amount
	emit_signal("currency_changed", currency)


func _make_key(item_id: String, rarity: String) -> String:
	if rarity == "":
		return item_id
	return "%s_%s" % [item_id, rarity]
