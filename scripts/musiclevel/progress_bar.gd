extends ProgressBar

var prev_hit = 0
var prev_miss = 0
var game_ended = false

func _on_referee_process(frame_state: FrameState) -> void:
	# Don't process if game already ended
	if game_ended:
		return
	
	# HIT
	if frame_state.scorecard.hits > prev_hit:
		if frame_state.scorecard.combo >= 10:
			value += (frame_state.scorecard.hits - prev_hit) * 4
		else:
			value += (frame_state.scorecard.hits - prev_hit)
		
	# MISS
	if frame_state.scorecard.misses > prev_miss:
		value -= (frame_state.scorecard.misses - prev_miss) * 5
		
	prev_hit = frame_state.scorecard.hits
	prev_miss = frame_state.scorecard.misses
	
	# Check if progress bar reached 0 or 100
	_check_completion()

func _check_completion() -> void:
	# Win condition: reached 100%
	if value >= max_value:
		game_ended = true
		print("✅ SUCCESS! Progress reached 100%")
		_show_result(true)
	
	# Lose condition: reached 0%
	elif value <= min_value:
		game_ended = true
		print("❌ FAILED! Progress reached 0%")
		_show_result(false)

func _show_result(won: bool) -> void:
	# Show result message
	if won:
		print("🎉 You caught the fish!")
	else:
		print("💔 The fish got away!")
	
	# Wait 2 seconds then return
	await get_tree().create_timer(0.5).timeout
	_return_to_previous_scene(won)

func _return_to_previous_scene(won: bool) -> void:
	var return_scene = _get_return_scene()
	
	print("[RhythmGame] Returning to: ", return_scene)
	
	# Give reward if won
	if won:
		_give_reward()
	
	# Return to scene - player will spawn at saved position
	get_tree().change_scene_to_file(return_scene)

func _get_return_scene() -> String:
	# Try to get the scene from GameStateManager
	# This makes it work from ANY level!
	
	# Check if GameStateManager exists as autoload
	if not has_node("/root/GameStateManager"):
		push_warning("[RhythmGame] GameStateManager not found - using fallback")
		return "res://scenes/overworld/terrain/tutorial_lake.tscn"
	
	var gsm = get_node("/root/GameStateManager")
	
	# Try pending_transition.from_scene first (most reliable)
	if gsm.pending_transition.has("from_scene") and gsm.pending_transition.from_scene != "":
		return gsm.pending_transition.from_scene
	
	# Try current_scene_path as fallback
	if gsm.current_save_data.current_scene_path != "":
		return gsm.current_save_data.current_scene_path
	
	# Final fallback
	push_warning("[RhythmGame] No return scene found - using tutorial lake")
	return "res://scenes/overworld/terrain/tutorial_lake.tscn"

func _give_reward() -> void:
	# Try to give reward if GameStateManager exists
	if not has_node("/root/GameStateManager"):
		return
	
	var gsm = get_node("/root/GameStateManager")
	
	# TODO: Uncomment when currency/inventory system is ready
	# gsm.current_save_data.currency += 50
	# gsm.current_save_data.inventory.append("fish")
	# gsm.autosave()
	
	print("[RhythmGame] 💰 Reward: +50 coins (placeholder)")
