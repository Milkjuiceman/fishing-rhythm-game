extends Label

func _on_referee_process(frame_state: FrameState) -> void:
	
	if not frame_state.scorecard:
		return
	var combo = frame_state.scorecard.combo
	var multiplier = 1
	var new_scale = Vector2(1,1)
	
	if combo >= 40:
		multiplier = 8
		new_scale = Vector2(2.5, 2.5)
	elif combo >= 20:
		multiplier = 4
		new_scale = Vector2(2, 2)
	elif combo >= 10:
		multiplier = 2
		new_scale = Vector2(1.5, 1.5)
	else:
		multiplier = 1
		new_scale = Vector2(1, 1)
	scale = new_scale
	text = str("X", multiplier)
