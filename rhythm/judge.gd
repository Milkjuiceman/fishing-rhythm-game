class_name Judge extends Node

var chart: Chart = null
var scorecard: Scorecard = null

const TEMPORAL_ERROR_MARGIN: float = 0.12 # 120ms

signal note_judged(note_index: int, frame_state: FrameState)

var lowest_judgment_index: int = 0

func load_new_chart(new_chart: Chart) -> void:
	chart = new_chart
	scorecard = Scorecard.new(new_chart)
	
func register_hit(compared_t: float, timing: float, i: int, frame_state: FrameState) -> void:
	var temporal_difference: float = compared_t - timing
	scorecard.hit_note(i, temporal_difference)
	scorecard.update_score(abs(temporal_difference), chart.note_column[i])
	note_judged.emit(i, frame_state)
	if i == lowest_judgment_index:
		lowest_judgment_index +=  1;
	
	
func process_and_fill_frame_state(frame_state: FrameState) -> void:
	if not frame_state.playing_song: return
	
	var lower_bound := frame_state.previous_t - TEMPORAL_ERROR_MARGIN + frame_state.input_offset
	var upper_bound := frame_state.t + TEMPORAL_ERROR_MARGIN + frame_state.input_offset
	var compared_t: float = lerp(frame_state.t, frame_state.previous_t, 0.5)
	
	# need to set this before doing the loop because the loop will emit signals with the frame_state in ti
	frame_state.scorecard = scorecard
	
	var i: int = lowest_judgment_index - 1
	while true:
		i += 1
		if i >= chart.note_timings.size(): # at end of song and all done
			_return_to_previous_scene()
			break
			
		var timing: float =  chart.note_timings[i]
		
		if timing > upper_bound: # done searching
			if frame_state.k_key_press || frame_state.j_key_press || frame_state.f_key_press || frame_state.d_key_press:
				# MISS
				scorecard.penalty(chart.note_column[i])
			break
		
		if scorecard.note_status[i] != Scorecard.NoteStateEnum.WAITING:
			# already judge this one (in a previous frame)
			continue
		
		if timing < lower_bound:
			# MISS
			scorecard.miss_note(i, chart.note_column[i])
			note_judged.emit(i, frame_state)
			lowest_judgment_index += 1
			
		else:
			if frame_state.k_key_press && chart.note_column[i] == 0:
				# HIT
				register_hit(compared_t, timing, i, frame_state)
				#var temporal_difference: float = compared_t - timing
				#scorecard.hit_note(i, temporal_difference)
				#note_judged.emit(i, frame_state)
				#if i == lowest_judgment_index:
					#lowest_judgment_index +=  1;
				#if abs(temporal_difference) <= .03:
					#print("perfect")
				#elif abs(temporal_difference) <= .07:
					#print("good")
				#else:
					#print("bad")
			elif frame_state.j_key_press && chart.note_column[i] == 1:
				# HIT
				register_hit(compared_t, timing, i, frame_state)
				#var temporal_difference: float = compared_t - timing
				#scorecard.hit_note(i, temporal_difference)
				#note_judged.emit(i, frame_state)
				#if i == lowest_judgment_index:
					#lowest_judgment_index +=  1;
				#if abs(temporal_difference) <= .03:
					#print("perfect")
				#elif abs(temporal_difference) <= .07:
					#print("good")
				#else:
					#print("bad")
			elif frame_state.f_key_press && chart.note_column[i] == 2:
				# HIT
				register_hit(compared_t, timing, i, frame_state)
				#var temporal_difference: float = compared_t - timing
				#scorecard.hit_note(i, temporal_difference)
				#note_judged.emit(i, frame_state)
				#if i == lowest_judgment_index:
					#lowest_judgment_index +=  1;
				#if abs(temporal_difference) <= .03:
					#print("perfect")
				#elif abs(temporal_difference) <= .07:
					#print("good")
				#else:
					#print("bad")
			elif frame_state.d_key_press && chart.note_column[i] == 3:
				# HIT
				register_hit(compared_t, timing, i, frame_state)
				#var temporal_difference: float = compared_t - timing
				#scorecard.hit_note(i, temporal_difference)
				#note_judged.emit(i, frame_state)
				#if i == lowest_judgment_index:
					#lowest_judgment_index +=  1;
				#if abs(temporal_difference) <= .03:
					#print("perfect")
				#elif abs(temporal_difference) <= .07:
					#print("good")
				#else:
					#print("bad")
			break


	# Return to prevoius scene logic
func _return_to_previous_scene() -> void:
	var return_scene = _get_return_scene()
	print("[Judge] Song completed! Returning to: ", return_scene)
	get_tree().change_scene_to_file(return_scene)

func _get_return_scene() -> String:
	if not has_node("/root/GameStateManager"):
		push_warning("[Judge] GameStateManager not found - using fallback")
		return "res://scenes/overworld/terrain/tutorial_lake.tscn"
	
	var gsm = get_node("/root/GameStateManager")
	
	if gsm.pending_transition.has("from_scene") and gsm.pending_transition.from_scene != "":
		return gsm.pending_transition.from_scene
	
	if gsm.current_save_data.current_scene_path != "":
		return gsm.current_save_data.current_scene_path
	
	push_warning("[Judge] No return scene found - using tutorial lake")
	return "res://scenes/overworld/terrain/tutorial_lake.tscn"
			
func _on_referee_play_chart_now(chart_: Chart) -> void:
	load_new_chart(chart_)
