extends Label

func _on_referee_process(frame_state: FrameState) -> void:
	text = str("SCORE: ", frame_state.scorecard.score);
