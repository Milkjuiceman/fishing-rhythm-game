extends Label

func _on_referee_process(frame_state: FrameState) -> void:
	var combo = frame_state.scorecard.combo
	var multiplier = 1
	var new_scale = Vector2(2,2)
	
	if combo >= 40:
		multiplier = 8
		new_scale = Vector2(5, 5)
	elif combo >= 20:
		multiplier = 4
		new_scale = Vector2(4, 4)
	elif combo >= 10:
		multiplier = 2
		new_scale = Vector2(3, 3)
	else:
		multiplier = 1
		new_scale = Vector2(2, 2)
	scale = new_scale
	text = str("X", multiplier);
