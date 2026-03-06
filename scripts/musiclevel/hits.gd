extends Label

func _on_referee_process(frame_state: FrameState) -> void:
	if frame_state.scorecard == null:
		return
		
	var sc = frame_state.scorecard
	text = "HITS: %d\nMISSES: %d\nCOMBO: %d" % [sc.hits, sc.misses, sc.combo]
