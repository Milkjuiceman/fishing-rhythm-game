extends Node
## InventoryManager Autoload
## Manages the player's item and fish inventory.
## Fish are tracked by fish_id (unique per rhythm level) for encyclopedia support.
## Author: [your name]
## Date of last update: 04/22/2026

signal inventory_changed(items: Dictionary)
signal currency_changed(new_amount: int)
signal item_changed(item_id: String, new_amount: int)
signal fish_caught(fish_id: String, new_count: int)

var items: Dictionary = {}
var currency: int

# ========================================
# SAVE / LOAD
# ========================================

func load_from_save(data: Dictionary) -> void:
	items = data.duplicate(true)
	inventory_changed.emit(items)

# ========================================
# FISH (ENCYCLOPEDIA) API
# ========================================

## Records a caught fish by its unique fish_id.
## This is the primary method called when a rhythm level is won.
func add_fish(fish_id: String, amount: int = 1) -> void:
	var key = _fish_key(fish_id)
	if not items.has(key):
		items[key] = 0
	items[key] += amount
	fish_caught.emit(fish_id, items[key])
	inventory_changed.emit(items)

## Returns how many times a specific fish has been caught (0 if never).
func get_fish_count(fish_id: String) -> int:
	return items.get(_fish_key(fish_id), 0)

## Returns true if the player has caught this fish at least once.
func has_caught_fish(fish_id: String) -> bool:
	return get_fish_count(fish_id) > 0

## Internal: builds the storage key for a fish entry.
func _fish_key(fish_id: String) -> String:
	return "fish::%s" % fish_id

# ========================================
# GENERIC ITEM API (unchanged)
# ========================================

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

func has_item(item_id: String, rarity: String = "", required_amount: int = 1) -> bool:
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
