extends CanvasLayer
class_name inventory_ui
## Fish Encyclopedia UI
## Displays all fish in the game grouped by area.
## Caught fish show green with catch count; uncaught fish show red.
## Reads fish definitions from FishRegistry and counts from InventoryManager.
## Author: [your name]
## Date of last update: 04/22/2026

# ========================================
# NODE REFERENCES
# ========================================

@onready var panel = $Panel
@onready var items_container: VBoxContainer = $Panel/VBoxContainer/VBoxContainer

# ========================================
# INITIALIZATION
# ========================================

func _ready():
	hide()
	InventoryManager.inventory_changed.connect(_refresh)
	_refresh(InventoryManager.items)

# ========================================
# VISIBILITY
# ========================================

func toggle():
	if is_visible():
		hide()
	else:
		show()
		_refresh(InventoryManager.items)

# ========================================
# ENCYCLOPEDIA DISPLAY
# ========================================

func _refresh(_items: Dictionary) -> void:
	# Clear existing entries
	for child in items_container.get_children():
		child.queue_free()

	# Build encyclopedia grouped by area
	for area_data in FishRegistry.get_all_areas():
		_add_area_header(area_data["area"])

		for fish in area_data["fish"]:
			var count = InventoryManager.get_fish_count(fish["fish_id"])
			_add_fish_entry(fish["display_name"], count)

# ========================================
# UI ELEMENT BUILDERS
# ========================================

func _add_area_header(area_name: String) -> void:
	var label = Label.new()
	label.text = "— %s —" % area_name
	label.add_theme_color_override("font_color", Color(0.8, 0.6, 0.2))  # Gold header
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	items_container.add_child(label)

func _add_fish_entry(display_name: String, count: int) -> void:
	var label = Label.new()

	if count > 0:
		# Caught: green, show count
		label.text = "%s  x%d" % [display_name, count]
		label.add_theme_color_override("font_color", Color(0.2, 0.85, 0.3))
	else:
		# Not yet caught: red
		label.text = "%s  x0" % display_name
		label.add_theme_color_override("font_color", Color(0.85, 0.2, 0.2))

	items_container.add_child(label)
