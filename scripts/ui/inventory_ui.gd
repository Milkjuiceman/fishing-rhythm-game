extends CanvasLayer
class_name inventory_ui
## Fish Encyclopedia UI
## Displays all fish in the game grouped by area.
## Caught fish show green with catch count; uncaught fish show red.
## Wraps into multiple columns, keeping area blocks together.

# ========================================
# NODE REFERENCES
# ========================================

@onready var panel = $Panel
@onready var items_container: VBoxContainer = $Panel/VBoxContainer/VBoxContainer

const ITEMS_PER_COLUMN := 10
const FONT_SIZE := 8

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
	for child in items_container.get_children():
		child.queue_free()

	# Group entries by area block
	var blocks: Array = []
	for area_data in FishRegistry.get_all_areas():
		var block: Array = []
		block.append({ "type": "header", "text": "— %s —" % area_data["area"] })
		for fish in area_data["fish"]:
			var count = InventoryManager.get_fish_count(fish["fish_id"])
			block.append({ "type": "fish", "text": "%s x%d" % [fish["display_name"], count], "caught": count > 0 })
		blocks.append(block)

	# Outer HBoxContainer fills the full width
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 0)
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	items_container.add_child(hbox)

	var col := _new_column()
	hbox.add_child(col)
	var col_count := 0

	for block in blocks:
		# If this block won't fit, start a new column
		if col_count > 0 and col_count + block.size() > ITEMS_PER_COLUMN:
			col = _new_column()
			hbox.add_child(col)
			col_count = 0

		for entry in block:
			var label := Label.new()
			label.text = entry["text"]
			label.add_theme_font_size_override("font_size", FONT_SIZE)
			label.add_theme_constant_override("line_spacing", -4)
			label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

			if entry["type"] == "header":
				label.add_theme_color_override("font_color", Color(0, 0, 0, 1))
				label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			elif entry["caught"]:
				label.add_theme_color_override("font_color", Color(0.2, 0.85, 0.3))
			else:
				label.add_theme_color_override("font_color", Color(0.85, 0.2, 0.2))

			col.add_child(label)

		col_count += block.size()

# ========================================
# HELPERS
# ========================================

func _new_column() -> VBoxContainer:
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 0)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	return vbox
