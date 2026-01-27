extends Label


func _on_referee_process(frame_state: FrameState) -> void:
	var combo = frame_state.scorecard.combo;
	
	if combo < 10:
		combo = 1
		scale = Vector2(3, 3)
	elif combo >= 10:
		combo = 4
		scale = Vector2(4, 4)
	else:
		combo = null
		scale = Vector2(1, 1)
		
	text = str("X", combo);
