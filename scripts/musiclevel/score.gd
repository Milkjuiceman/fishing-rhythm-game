extends Label

func _on_referee_process(frame_state: FrameState) -> void:
	if frame_state.scorecard == null:
		return
		
	text = str("SCORE: ", frame_state.scorecard.score)