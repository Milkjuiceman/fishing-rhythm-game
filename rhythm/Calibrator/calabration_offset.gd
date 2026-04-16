extends Label



func _on_referee_process(frame_state: FrameState) -> void:
	
	if frame_state.scorecard.hits >= 10:
		var audio_offset = -round(frame_state.scorecard.get_average_temporal_offset() * 100.0) / 100.0
		var pause_menu = get_node_or_null("/root/PauseMenu")
		pause_menu._on_audio_offset_changed(audio_offset)
		text = str("Audio Offset: ", audio_offset )
