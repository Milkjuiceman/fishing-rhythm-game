extends Control

var scroll_speed: int = 50

func _process(delta: float) -> void:
	$Credits.position.y -= delta * scroll_speed
	
	if $Credits.position.y < -1600:
		set_process(false)
		await get_tree().create_timer(1.5).timeout
		get_tree().change_scene_to_file("res://main_menu.tscn")
