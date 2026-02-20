extends ProgressBar

var prev_hit = 0;
var prev_miss = 0;
signal catch_failed
signal catch_available

var catchable := false


func _on_referee_process(frame_state: FrameState) -> void:
	if not frame_state.playing_song:
		return
	# Process hits 
	if frame_state.scorecard.hits > prev_hit:
		if frame_state.scorecard.combo >= 10:
			value += (frame_state.scorecard.hits - prev_hit) * 6  
		elif frame_state.scorecard.combo >= 20:
			value += (frame_state.scorecard.hits - prev_hit) * 8
		else:
			value += (frame_state.scorecard.hits - prev_hit) * 4
	
	# Process misses 
	if frame_state.scorecard.misses > prev_miss:
		value -= (frame_state.scorecard.misses - prev_miss) * 8  
	
	# Update tracking variables
	prev_hit = frame_state.scorecard.hits
	prev_miss = frame_state.scorecard.misses
	
	# Check if player hit 0% AND level is failabe
	if value <= min_value and frame_state.scorecard.start_buffer <= 0:
		print("{ProgressBar} depeleted, level failed")
		emit_signal("catch_failed")
		
	if value <= max_value and not catchable:
		print("[ProgressBar]: filled, fish catchable")
		catchable = true
		emit_signal("catch_available")
