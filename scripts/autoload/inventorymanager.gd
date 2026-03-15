extends Node
## Inventory Manager (AutoLoad: InventoryManager)
## Manages the player's item inventory and coin currency.
## Items stored as key → quantity using _make_key(id, rarity).

signal inventory_changed(items: Dictionary)
signal currency_changed(new_amount: int)
signal item_changed(item_id: String, new_amount: int)

var items: Dictionary = {}
var currency: int = 0

# ========================================
# SAVE / LOAD
# ========================================

## Load inventory and currency from a PlayerSaveData.
func load_from_save(data: Dictionary, saved_currency: int = 0) -> void:
	items    = data.duplicate(true)
	currency = saved_currency
	inventory_changed.emit(items)
	currency_changed.emit(currency)

# ========================================
# ITEM MANAGEMENT
# ========================================

func add_item(item_id: String, rarity: String = "", amount: int = 1) -> void:
	var key := _make_key(item_id, rarity)
	if not items.has(key):
		items[key] = 0
	items[key] += amount
	if items[key] <= 0:
		items.erase(key)
		item_changed.emit(item_id, 0)
	else:
		item_changed.emit(item_id, items[key])
	inventory_changed.emit(items)

func remove_item(item_id: String, rarity: String = "", amount: int = 1) -> void:
	add_item(item_id, rarity, -amount)

func has_item(item_id: String, rarity: String = "", required_amount: int = 1) -> bool:
	return get_item_count(item_id, rarity) >= required_amount

func get_item_count(item_id: String, rarity: String = "") -> int:
	var key := _make_key(item_id, rarity)
	return items.get(key, 0)

# ========================================
# CURRENCY MANAGEMENT
# ========================================

func add_currency(amount: int) -> void:
	currency += amount
	currency_changed.emit(currency)

## Deduct currency. Call can_afford() first.
func spend_currency(amount: int) -> void:
	if amount > currency:
		push_warning("[InventoryManager] spend_currency called with insufficient funds!")
		return
	currency -= amount
	currency_changed.emit(currency)

## Returns true if the player has enough coins for the given cost.
func can_afford(cost: int) -> bool:
	return currency >= cost

func get_currency() -> int:
	return currency

# ========================================
# HELPERS
# ========================================

func _make_key(item_id: String, rarity: String) -> String:
	if rarity == "":
		return item_id
	return "%s_%s" % [item_id, rarity]
