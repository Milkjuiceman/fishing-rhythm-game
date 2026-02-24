extends Label

func _on_referee_process(frame_state: FrameState) -> void:
	var sc = frame_state.scorecard
	text = "HITS: %d\nMISSES: %d\nCOMBO: %d" % [sc.hits, sc.misses, sc.combo]
