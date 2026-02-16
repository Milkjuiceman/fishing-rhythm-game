extends Label



func _on_referee_process(frame_state: FrameState) -> void:
	
	if frame_state.scorecard.hits >= 10:
		text = str("Audio Offset: ", -round(frame_state.scorecard.get_average_temporal_offset() * 100.0) / 100.0 )
