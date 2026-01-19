extends Control
## This Control node holds the Audio/Input offset sliders for the rhythm section.
## Pause functionality is handled by the global PauseMenu AutoLoad.

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	for child in get_children():
		if child is Control and not (child is HSlider or child is Button):
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE