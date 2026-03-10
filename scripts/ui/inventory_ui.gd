extends CanvasLayer
class_name inventory_ui

@onready var panel = $Panel
@onready var items_container: VBoxContainer = $Panel/VBoxContainer/VBoxContainer

func _ready():
	hide()
	InventoryManager.inventory_changed.connect(_refresh)
	_refresh(InventoryManager.items)
		
func toggle():
	if is_visible():
		hide()
	else:
		show()
		
func _refresh(items: Dictionary):
	for child in items_container.get_children():
		child.queue_free()
		
	for key in items.keys():
		var label = Label.new()
		label.text = "%s x %d" % [key, items[key]]
		items_container.add_child(label)
