extends ProgressBar

var prev_hits: int = 0

func _on_referee_process(frame_state: FrameState) -> void:
	
	if frame_state.scorecard.hits > prev_hits:
		prev_hits += 1
		value += 10
		
	if value == 100:
		get_tree().paused = true
