extends ProgressBar
## Rhythm Game Progress Bar
## Tracks player performance during fishing minigame based on hits and misses
## Boots player back to previous scene if progress reaches 0%

var prev_hit = 0  # Track previous hit count
var prev_miss = 0  # Track previous miss count

# Update progress bar based on rhythm game performance
func _on_referee_process(frame_state: FrameState) -> void:
	# Process hits 
	if frame_state.scorecard.hits > prev_hit:
		if frame_state.scorecard.combo >= 10:
			value += (frame_state.scorecard.hits - prev_hit) * 4  
		else:
			value += (frame_state.scorecard.hits - prev_hit)  
	
	# Process misses 
	if frame_state.scorecard.misses > prev_miss:
		value -= (frame_state.scorecard.misses - prev_miss) * 5  
	
	# Update tracking variables
	prev_hit = frame_state.scorecard.hits
	prev_miss = frame_state.scorecard.misses
	
	# Check if player hit 0% 
	#if value <= min_value:
		#_return_to_previous_scene()

# Return player to the scene they came from
func _return_to_previous_scene() -> void:
	var return_scene = _get_return_scene()
	print("[ProgressBar] Returning to: ", return_scene)
	get_tree().change_scene_to_file(return_scene)

# Get the scene path to return to
func _get_return_scene() -> String:
	if not has_node("/root/GameStateManager"):
		push_warning("[ProgressBar] GameStateManager not found - using fallback")
		return "res://scenes/overworld/terrain/tutorial_lake.tscn"
	
	var gsm = get_node("/root/GameStateManager")
	
	if gsm.pending_transition.has("from_scene") and gsm.pending_transition.from_scene != "":
		return gsm.pending_transition.from_scene
	
	if gsm.current_save_data.current_scene_path != "":
		return gsm.current_save_data.current_scene_path
	
	push_warning("[ProgressBar] No return scene found - using tutorial lake")
	return "res://scenes/overworld/terrain/tutorial_lake.tscn"
