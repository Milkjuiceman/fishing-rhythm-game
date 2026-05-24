extends Control

var scroll_speed: int = 50

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	$Credits.position.y -= delta * scroll_speed
	
	if $Credits.position.y < -1600:
		set_process(false)
