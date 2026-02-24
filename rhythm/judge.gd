extends Node
class_name Judge 

# node references
@export var progress_bar: CatchProgressBar
var chart: Chart = null
var scorecard: Scorecard = null
# signals 
signal song_finished
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
	
	var i: int = lowest_judgment_index - 1
	while true:
		i += 1
		if i >= chart.note_timings.size(): # at end of song
			emit_signal("song_finished")
			break
			
		var timing =  chart.note_timings[i]
		
		if timing > upper_bound:
			# late keypress is a miss
			if frame_state.k_key_press || frame_state.j_key_press || frame_state.f_key_press || frame_state.d_key_press:
					scorecard.miss_note(i)
			break
		
		if scorecard.note_status[i] != Scorecard.NoteStateEnum.WAITING:
			# already judge this one (in a previous frame)
			continue
		
		if timing < lower_bound:
			scorecard.miss_note(i)
			lowest_judgment_index += 1
			# print("Miss registered! Total misses:", scorecard.misses)
		else:
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
				if i == lowest_judgment_index:
					lowest_judgment_index += 1
				# print("Hit registered! Total hits:", scorecard.hits, "Combo:", scorecard.combo)
			break
	if progress_bar != null:
		progress_bar._update_from_scorecard(scorecard)
