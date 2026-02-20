class_name Judge extends Node

var chart: Chart = null
var scorecard: Scorecard = null

const TEMPORAL_ERROR_MARGIN: float = 0.1 # 100ms

signal note_judged(note_index: int, frame_state: FrameState)

var lowest_judgment_index: int = 0

signal song_finished(scorecard: Scorecard)

var first_bar_full: bool = false

@export var progress_bar: ProgressBar
var can_catch := false

func _ready():
	progress_bar.catch_available.connect(_on_catch_available)
	progress_bar.catch_failed.connect(_on_catch_failed)

func load_new_chart(new_chart: Chart) -> void:
	chart = new_chart
	scorecard = Scorecard.new(new_chart)


func process_and_fill_frame_state(frame_state: FrameState) -> void:
	if not frame_state.playing_song: return
	
		
	if can_catch and frame_state.enter_key_press:
			show_enter_prompt(false)
			_return_to_previous_scene()
			return
	
	var lower_bound := frame_state.previous_t - TEMPORAL_ERROR_MARGIN + frame_state.input_offset
	var upper_bound := frame_state.t + TEMPORAL_ERROR_MARGIN + frame_state.input_offset
	var compared_t: float = lerp(frame_state.t, frame_state.previous_t, 0.5)
	
	# need to set this before doing the loop because the loop will emit signals with the frame_state in ti
	frame_state.scorecard = scorecard
	
	var i: int = lowest_judgment_index - 1
	while true:
		i += 1
		if i >= chart.note_timings.size(): # at end of song and all done
			break
		
		#if i > chart.note_timings.size() - 2:
			#if frame_state.k_key_press:
				#print("k0: ", frame_state.t, "\n");
				#
			#if frame_state.j_key_press:
				#print("j1: ", frame_state.t, "\n");
				#
			#if frame_state.f_key_press:
				#print("f2: ", frame_state.t, "\n");
				#
			#if frame_state.d_key_press:
				#print("d3: ", frame_state.t, "\n");
			
		var timing: float =  chart.note_timings[i]
		
		if timing > upper_bound: # done searching
			if frame_state.k_key_press || frame_state.j_key_press || frame_state.f_key_press || frame_state.d_key_press:
				# MISS
				scorecard.penalty()
			break
		
		if scorecard.note_status[i] != Scorecard.NoteStateEnum.WAITING:
			# already judge this one (in a previous frame)
			continue
		
		if timing < lower_bound:
			# MISS
			scorecard.miss_note(i)
			note_judged.emit(i, frame_state)
			lowest_judgment_index += 1
	
		else:
			if frame_state.k_key_press && chart.note_column[i] == 0:
				# HIT
				var temporal_difference: float = compared_t - timing
				scorecard.hit_note(i, temporal_difference)
				note_judged.emit(i, frame_state)
				if i == lowest_judgment_index:
					lowest_judgment_index +=  1;
			elif frame_state.j_key_press && chart.note_column[i] == 1:
				# HIT
				var temporal_difference: float = compared_t - timing
				scorecard.hit_note(i, temporal_difference)
				note_judged.emit(i, frame_state)
				if i == lowest_judgment_index:
					lowest_judgment_index +=  1;
			elif frame_state.f_key_press && chart.note_column[i] == 2:
				# HIT
				var temporal_difference: float = compared_t - timing
				scorecard.hit_note(i, temporal_difference)
				note_judged.emit(i, frame_state)
				if i == lowest_judgment_index:
					lowest_judgment_index +=  1;
			elif frame_state.d_key_press && chart.note_column[i] == 3:
				# HIT
				var temporal_difference: float = compared_t - timing
				scorecard.hit_note(i, temporal_difference)
				note_judged.emit(i, frame_state)
				if i == lowest_judgment_index:
					lowest_judgment_index +=  1;
			break


func _on_catch_failed() -> void:
	print("[Judge]:bar depleted, ending song")
	_return_to_previous_scene()
	
func _on_catch_available() -> void:
	print("[Judge]:bar filled, press enter to catch early")
	can_catch = true
	show_enter_prompt(true)

	# Return to prevoius scene logic
func _return_to_previous_scene() -> void:
	var return_scene = _get_return_scene()
	song_finished.emit(scorecard)
	print("[Judge] Song completed! Returning to: ", return_scene)
	print("[Judge] Your score was: ", scorecard)
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

func show_enter_prompt(visible: bool) -> void:
	var oops = 1
	#if has_node("/root/UI/EnterPrompt"):
		#$"/root/UI/EnterPrompt".visible = visible
