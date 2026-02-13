class_name Judge extends Node

var chart: Chart = null
var scorecard: Scorecard = null

const TEMPORAL_ERROR_MARGIN: float = 0.1 # 100ms

signal note_judged(note_index: int, frame_state: FrameState)

var lowest_judgment_index: int = 0


func load_new_chart(new_chart: Chart) -> void:
	chart = new_chart
	scorecard = Scorecard.new(new_chart)


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
			get_tree().change_scene_to_file("res://graphics/pixelate.tscn")
			break
			
		if frame_state.k_key_press:
			print("k press: ", i, " ", compared_t)
		elif frame_state.j_key_press:
			print("j press: ", i, " ", compared_t)
		elif frame_state.f_key_press:
			print("f press: ", i, " ", compared_t)
		elif frame_state.d_key_press:
			print("d press: ", i, " ", compared_t)
			
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
			


func _on_referee_play_chart_now(chart_: Chart) -> void:
	load_new_chart(chart_)
