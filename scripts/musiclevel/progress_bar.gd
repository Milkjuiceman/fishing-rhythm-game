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
		value -= frame_state.scorecard.misses - prev_miss
		
	prev_hit = frame_state.scorecard.hits
	prev_miss = frame_state.scorecard.misses
	
	# LOSE - return to previous scene
	if value < 0:
		return_to_overworld()
	
	# WIN - return to previous scene
	if value >= 100:
		return_to_overworld()

func return_to_overworld():
	# Get the scene path that was saved when we entered the minigame
	var return_scene = BoatManager.return_scene_path
	
	# If we don't have a saved return scene, default to main
	if return_scene == "":
		return_scene = "res://main.tscn"
	
	# Change back to the overworld scene
	# The player will be loaded at the saved position automatically
	get_tree().change_scene_to_file(return_scene)
