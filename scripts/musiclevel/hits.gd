extends Label


func _on_referee_process(frame_state: FrameState) -> void:
	text = str("HITS: ", frame_state.scorecard.hits, "\n", "MISSES: ", frame_state.scorecard.misses, "\n", "COMBO: ", frame_state.scorecard.combo);
