extends Node
class_name RhythmJudge 

# node references
@export var progress_bar: CatchProgressBar
var chart: Chart = null
var scorecard: Scorecard = null

# signals 
signal song_finished
signal note_judged(note_index: int, frame_state: FrameState)

# state 
var lowest_judgment_index: int = 0

func _ready():
	scorecard = Scorecard.new()
	if progress_bar:
		progress_bar.reset()

func load_new_chart(new_chart: Chart) -> void:
	chart = new_chart
	if chart != null:
		scorecard = Scorecard.new(chart)
		lowest_judgment_index = 0
		progress_bar.reset()
		
func process_and_fill_frame_state(frame_state: FrameState) -> void:
	if not frame_state.playing_song or chart == null: 
		return
	
	# sync with other system
	frame_state.scorecard = scorecard
	
	var lower_bound := frame_state.previous_t - 0.12 + frame_state.input_offset
	var upper_bound := frame_state.t + 0.12 + frame_state.input_offset
	var compared_t: float = lerp(frame_state.t, frame_state.previous_t, 0.5)
	
	# part 1: clean up by advancing lowest_judgement_index when notes are definitely missed
	while lowest_judgment_index < chart.note_timings.size():
		var timing = chart.note_timings[lowest_judgment_index]
		
		if scorecard.note_status[lowest_judgment_index] != Scorecard.NoteStateEnum.WAITING:
			lowest_judgment_index += 1
			continue
		
		if timing < lower_bound:
			scorecard.miss_note(lowest_judgment_index)
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
				hit = true
			elif frame_state.j_key_press && chart.note_column[i] == 1:
				hit = true
			elif frame_state.f_key_press && chart.note_column[i] == 2:
				hit = true
			elif frame_state.d_key_press && chart.note_column[i] == 3:
				hit = true
			
			if hit:
				scorecard.hit_note(i, compared_t - timing)
				break
	
	if progress_bar != null:
		progress_bar._update_from_scorecard(scorecard)
		
	if lowest_judgment_index >= chart.note_timings.size():
		emit_signal("song_finished")
		
