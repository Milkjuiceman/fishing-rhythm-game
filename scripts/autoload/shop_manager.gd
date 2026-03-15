extends Node
## Shop Manager (AutoLoad: ShopManager)
## Central catalog of all purchasable items in the game.
## Add new items here — ShopNPC scenes reference items by id string.

# ========================================
# SIGNALS
# ========================================

signal purchase_succeeded(item_id: String, quantity: int)
signal purchase_failed(item_id: String, reason: String)

# ========================================
# ITEM CATALOG
# ========================================
# Fields per entry:
#   id           — unique key referenced everywhere
#   display_name — shown in shop UI
#   description  — flavour text
#   price        — cost in coins
#   category     — "bait" | "upgrade" | "misc" (future tab filtering)
#   max_stack    — max quantity player can own; -1 = unlimited

const ITEM_CATALOG: Array[Dictionary] = [
	# ── Bait ──────────────────────────────────────────────────────────────
	{
		"id":           "worm_bait",
		"display_name": "Worm Bait",
		"description":  "Tried-and-true bait. Reliable in any lake.",
		"price":        10,
		"category":     "bait",
		"max_stack":    99,
	},
	{
		"id":           "shiny_lure",
		"display_name": "Shiny Lure",
		"description":  "Glints underwater. Attracts bigger fish.",
		"price":        25,
		"category":     "bait",
		"max_stack":    99,
	},
	{
		"id":           "mystery_bait",
		"display_name": "Mystery Bait",
		"description":  "Nobody knows what's in it, but fish love it.",
		"price":        50,
		"category":     "bait",
		"max_stack":    20,
	},
	# ── Upgrades ──────────────────────────────────────────────────────────
	{
		"id":           "rod_upgrade",
		"display_name": "Reinforced Rod",
		"description":  "Reduces note misses during rhythm sections.",
		"price":        150,
		"category":     "upgrade",
		"max_stack":    1,
	},
	{
		"id":           "lucky_hook",
		"display_name": "Lucky Hook",
		"description":  "Slightly increases the chance of a rare or better catch.",
		"price":        200,
		"category":     "upgrade",
		"max_stack":    1,
	},
	# ── Misc ──────────────────────────────────────────────────────────────
	{
		"id":           "fish_almanac",
		"display_name": "Fisher's Almanac",
		"description":  "Keeps a record of every known fish species in the area.",
		"price":        75,
		"category":     "misc",
		"max_stack":    1,
	},
]

# ========================================
# INTERNAL LOOKUP
# ========================================

var _catalog_by_id: Dictionary = {}

func _ready() -> void:
	for entry in ITEM_CATALOG:
		_catalog_by_id[entry["id"]] = entry

# ========================================
# CATALOG QUERIES
# ========================================

## Return full item data dict for an id, or {} if unknown.
func get_item(item_id: String) -> Dictionary:
	return _catalog_by_id.get(item_id, {})

## Return only items whose ids appear in the given list.
## Used by ShopNPC to build per-NPC inventory.
func get_items_for_ids(ids: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for id in ids:
		var entry: Dictionary = _catalog_by_id.get(id, {})
		if not entry.is_empty():
			result.append(entry)
	return result

# ========================================
# PURCHASE LOGIC
# ========================================

## Attempt to buy one unit of item_id.
## Returns true on success. Emits purchase_succeeded or purchase_failed.
func try_purchase(item_id: String, quantity: int = 1) -> bool:
	var item := get_item(item_id)
	if item.is_empty():
		push_warning("[ShopManager] Unknown item id: %s" % item_id)
		purchase_failed.emit(item_id, "unknown_item")
		return false

	var total_cost: int = item["price"] * quantity

	if not InventoryManager.can_afford(total_cost):
		purchase_failed.emit(item_id, "insufficient_funds")
		return false

	if item["max_stack"] > 0:
		var current: int = InventoryManager.get_item_count(item_id)
		if current + quantity > item["max_stack"]:
			purchase_failed.emit(item_id, "max_stack_reached")
			return false

	InventoryManager.spend_currency(total_cost)
	InventoryManager.add_item(item_id, "", quantity)

	purchase_succeeded.emit(item_id, quantity)
	print_debug("[ShopManager] Purchased %d x %s for %d coins." % [quantity, item_id, total_cost])
	return true