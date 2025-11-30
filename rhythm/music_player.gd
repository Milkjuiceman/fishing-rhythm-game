class_name MusicPlayer extends AudioStreamPlayer

var current_track: Track

var _previous_t: float

var offset: float = 0

func play_track(track_to_pay: Track) -> void:
	current_track = track_to_pay
	stream = current_track.load_stream()
	play()


func fill_frame_state(frame_delta: float, frame_state: FrameState) -> void:
	if current_track == null:
		frame_state.playing_song = false
		frame_state.t = offset
		frame_state.delta = frame_delta
		
		_previous_t = -1.
	
	else:
		frame_state.playing_song = true
		frame_state.t = get_playback_position() + AudioServer.get_time_since_last_mix() + offset
		if _previous_t != -1.:
			frame_state.delta = frame_state.t - _previous_t
		else:
			frame_state.delta = frame_state.t
		
		_previous_t = frame_state.t
		
		current_track.fill_frame_state(frame_state)
	
	frame_state.previous_t = frame_state.t - frame_state.delta


func _on_finished() -> void:
	_previous_t = 0.
	current_track = null


func _on_referee_play_chart_now(chart: Chart) -> void:
	_previous_t = 0.
	play_track(chart.track)


func _on_offset_slider_change_audio_offset(offset_: float) -> void:
	offset = offset_
