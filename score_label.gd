extends Label



func _on_referee_process(frame_state: FrameState) -> void:
	text = str("Score: ", frame_state.scorecard.combo)
