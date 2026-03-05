extends CanvasLayer

@onready var panel = $Panel

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
	for child in panel.get_children():
		child.queue_free()
	for key in items.keys():
		var label = Label.new()
		label.text = "%s x %d" % [key, items[key]]
		panel.add_child(label)
