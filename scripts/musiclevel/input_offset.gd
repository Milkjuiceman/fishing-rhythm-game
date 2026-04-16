extends Label


func _on_judge_calibration_finished(offset_sec: float) -> void:
	var input_offset = round(offset_sec * 100 ) / 100
	var pause_menu = get_node_or_null("/root/PauseMenu")
	pause_menu._on_input_offset_changed(input_offset)
	text = str("Input Offset: ", input_offset )
