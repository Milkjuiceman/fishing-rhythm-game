extends Node

var currency: int = 0
var large_fish: int = 0
var fish_inventory: Dictionary = {}
var school_fish: int = 0

signal currency_changed(new_amount)
signal inventory_changed()

func add_currency(amount: int) -> void:
	currency += amount
	emit_signal("currency_changed", currency)
	
func add_item(fish_type: String, amount: int = 1) -> void:
	if not fish_inventory.has(fish_type):
		fish_inventory[fish_type] = 0
	fish_inventory[fish_type] += amount
	emit_signal("inventory_changed")
