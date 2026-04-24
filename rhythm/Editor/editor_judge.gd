class_name EditorJudge extends Node

@export var testing = false
@export var start = 0.0
@export var finish = 0.0

var session_active := false

var chart: Chart = null
var scorecard: Scorecard = null

const TEMPORAL_ERROR_MARGIN: float = 0.12 # 120ms

signal note_judged(note_index: int, frame_state: FrameState)
signal send_key_times(key_times: PackedFloat64Array, key_columns: PackedInt64Array, start: float, finish: float)

var lowest_judgment_index: int = 0
var key_times: PackedFloat64Array = PackedFloat64Array()
var key_columns: PackedInt64Array = PackedInt64Array()
var ghost_inputs: PackedFloat64Array = PackedFloat64Array()

func start_session() -> void:
	session_active = true
	key_times.clear()
	key_columns.clear()
	ghost_inputs.clear()
	if finish <= start:
		finish = start + 60.0 
		push_warning("[Judge] Finish time was invalid. Fallback to +60s.")
	print("[Judge] Window: ", start, "s to ", finish, "s (Duration: ", finish - start, "s)")
	
	if testing:
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, true)
		get_window().grab_focus()

	lowest_judgment_index = 0
		
	if chart != null:
		if scorecard.note_columns_pressed.size() == 0:
			scorecard.note_columns_pressed.resize(chart.note_timings.size())
			scorecard.note_columns_pressed.fill(-1)
			
		for i in range(chart.note_timings.size()):
			if chart.note_timings[i] >= start:
				lowest_judgment_index = i
				break

func load_new_chart(new_chart: Chart) -> void:
	chart = new_chart
	scorecard = Scorecard.new(new_chart)
	
func process_and_fill_frame_state(frame_state: FrameState) -> void:
	if not frame_state.playing_song:
		if session_active:
			print("[Judge] Song ended naturally before 'finish' time. Ending session.")
			end_test_run(frame_state)
		return

	# Check for completion using ABSOLUTE time
	if frame_state.t > finish:
		print("[Judge] Reached finish time: ", finish)
		end_test_run(frame_state)
		return

	# Ignore notes before the 'start' time
	if frame_state.t < start:
		return
	
	frame_state.scorecard = scorecard
	
	# capture input
	var current_col = -1
	if frame_state.k_key_press: current_col = 0
	elif frame_state.j_key_press: current_col = 1
	elif frame_state.f_key_press: current_col = 2
	elif frame_state.d_key_press: current_col = 3
	
	if current_col != -1:
		ghost_inputs.append(frame_state.t)
	
	if not testing:
		if current_col != -1:
			key_times.append(frame_state.t)
			key_columns.append(current_col)
		return # exit early; don't run judgment logic if recording
		
	# only runs if testing mode is enabled
	for i in range(lowest_judgment_index, chart.note_timings.size()):
		var note_time: float = chart.note_timings[i]

		# Skip already processed notes
		if scorecard.note_status[i] != Scorecard.NoteStateEnum.WAITING:
			if i == lowest_judgment_index:
				lowest_judgment_index += 1
			continue

		# If note is too far in future, stop checking for this frame
		if note_time > frame_state.t + TEMPORAL_ERROR_MARGIN:
			break
		
		# Check for MISS
		if frame_state.t > note_time + TEMPORAL_ERROR_MARGIN:
			scorecard.miss_note(i, chart.note_column[i])
			note_judged.emit(i, frame_state)
			lowest_judgment_index = i + 1
			continue

		# Check for HIT
		if current_col != -1:
			var diff: float = frame_state.t - note_time
			
			# Record the hit
			scorecard.hit_note(i, diff)
			scorecard.note_columns_pressed[i] = current_col # Save what you actually pressed
			
			note_judged.emit(i, frame_state)
			if i == lowest_judgment_index:
				lowest_judgment_index += 1
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

func end_test_run(frame_state: FrameState) -> void:
	# Stop audio if present
	session_active = false
	emit_signal("send_key_times", key_times, key_columns, start, finish)
	if frame_state.has_method("stop_song"):
		frame_state.stop_song()
	if testing:
		get_tree().quit()
