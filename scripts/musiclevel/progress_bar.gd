extends ProgressBar

var prev_hit = 0
var prev_miss = 0

func _on_referee_process(frame_state: FrameState) -> void:
	
	# HIT
	if frame_state.scorecard.hits > prev_hit:
		if frame_state.scorecard.combo >= 10:
			value += (frame_state.scorecard.hits - prev_hit) * 4
		else:
			value += (frame_state.scorecard.hits - prev_hit)
		
	#MISS
	if frame_state.scorecard.misses > prev_miss:
		value -= (frame_state.scorecard.misses - prev_miss) * 5
		
	prev_hit = frame_state.scorecard.hits
	prev_miss = frame_state.scorecard.misses
	
	#if value < 0:
		#get_tree().change_scene_to_file("res://graphics/pixelate.tscn")
