extends Label


func _on_judge_calibration_finished(offset_sec: float) -> void:
	text = str("Input Offset: ", round(offset_sec * 100 ) / 100 )
