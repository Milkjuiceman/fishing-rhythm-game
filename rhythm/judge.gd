extends Node
class_name RhythmJudge 

# node references
@export var progress_bar: CatchProgressBar
var chart: Chart = null
var scorecard: Scorecard = null

const TEMPORAL_ERROR_MARGIN: float = 0.12 # 120ms

# signals 
signal song_finished
signal note_judged(note_index: int, frame_state: FrameState)

# state 
var lowest_judgment_index: int = 0
  
  func load_new_chart(new_chart: Chart) -> void:
	chart = new_chart
	if chart != null:
		scorecard = Scorecard.new(chart)
		lowest_judgment_index = 0
		progress_bar.reset()
	
func register_hit(compared_t: float, timing: float, i: int, frame_state: FrameState) -> void:
	var temporal_difference: float = compared_t - timing
	scorecard.hit_note(i, temporal_difference)
	scorecard.update_score(abs(temporal_difference), chart.note_column[i])
	note_judged.emit(i, frame_state)
	if i == lowest_judgment_index:
		lowest_judgment_index +=  1;

# func _ready():
	# scorecard = Scorecard.new()
	# if progress_bar:
		# progress_bar.reset()
		
func process_and_fill_frame_state(frame_state: FrameState) -> void:
	if not frame_state.playing_song or chart == null: 
		return
	
	# sync with other system
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
      
	var lower_bound := frame_state.previous_t - 0.12 + frame_state.input_offset
	var upper_bound := frame_state.t + 0.12 + frame_state.input_offset
	var compared_t: float = lerp(frame_state.t, frame_state.previous_t, 0.5)
	
	# part 1: clean up by advancing lowest_judgement_index when notes are definitely missed
	# while lowest_judgment_index < chart.note_timings.size():
		# var timing = chart.note_timings[lowest_judgment_index]
		
		if scorecard.note_status[lowest_judgment_index] != Scorecard.NoteStateEnum.WAITING:
			lowest_judgment_index += 1
			continue
		
		if timing < lower_bound:
			# MISS
			scorecard.miss_note(i, chart.note_column[i])
			note_judged.emit(i, frame_state)
			lowest_judgment_index += 1
		else: # note still in hit window
			break
			
	# part 2: hit detection
	var any_key_press = frame_state.k_key_press || frame_state.j_key_press || frame_state.f_key_press || frame_state.d_key_press
	
	if any_key_press:
		for i in range(lowest_judgment_index, chart.note_timings.size()):
			var timing = chart.note_timings[i]
			
			if timing > upper_bound:
				break
				
			if scorecard.note_status[i]  != Scorecard.NoteStateEnum.WAITING:
				continue
				
			var hit = false
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
			
			if hit:
				scorecard.hit_note(i, compared_t - timing)
				break
	
	if progress_bar != null:
		progress_bar._update_from_scorecard(scorecard)
		
	if lowest_judgment_index >= chart.note_timings.size():
		emit_signal("song_finished")
		
