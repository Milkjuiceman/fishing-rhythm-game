class_name Judge extends Node

var chart: Chart = null
var scorecard: Scorecard = null

const TEMPORAL_ERROR_MARGIN: float = 0.1 # 100ms

signal note_judged(note_index: int, frame_state: FrameState)


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
	
	var i: int = 0 # TODO! The following loop is a merely an example template 
	while false:
		var timing: float =  chart.note_timings[i]
		
		if timing > upper_bound: # done searching
			continue # TODO or break depending on implementaiton
		
		if scorecard.note_status[i] != Scorecard.NoteStateEnum.WAITING:
			# already judge this one (in a previous frame)
			continue
		
		if timing < lower_bound:
			# MISS
			scorecard.miss_note(i)
			note_judged.emit(i, frame_state)
		else:
			# HIT
			var temporal_difference: float = compared_t - timing
			scorecard.hit_note(i, temporal_difference)
			note_judged.emit(i, frame_state)
