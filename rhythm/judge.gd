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


func _ready() -> void:
	# Wire song_finished to scene return
	song_finished.connect(_return_to_previous_scene)


func load_new_chart(new_chart: Chart) -> void:
	chart = new_chart
	if chart != null:
		scorecard = Scorecard.new(chart)
		lowest_judgment_index = 0
		if progress_bar:
			progress_bar.reset()


func register_hit(compared_t: float, timing: float, i: int, frame_state: FrameState) -> void:
	var temporal_difference: float = compared_t - timing
	scorecard.hit_note(i, temporal_difference)
	scorecard.update_score(abs(temporal_difference), chart.note_column[i])
	note_judged.emit(i, frame_state)
	if i == lowest_judgment_index:
		lowest_judgment_index += 1


func process_and_fill_frame_state(frame_state: FrameState) -> void:
	# Guard: need both a playing song and an initialized scorecard
	if not frame_state.playing_song or chart == null or scorecard == null:
		return

	# Set scorecard on frame_state now that we know it's valid
	frame_state.scorecard = scorecard

	var lower_bound := frame_state.previous_t - TEMPORAL_ERROR_MARGIN + frame_state.input_offset
	var upper_bound := frame_state.t + TEMPORAL_ERROR_MARGIN + frame_state.input_offset
	var compared_t: float = lerp(frame_state.t, frame_state.previous_t, 0.5)

	var i: int = lowest_judgment_index - 1
	while true:
		i += 1

		# End of chart — song complete
		if i >= chart.note_timings.size():
			emit_signal("song_finished")
			break

		var timing: float = chart.note_timings[i]

		# Note is too far ahead — stop searching this frame
		if timing > upper_bound:
			# Penalise a stray key press
			if frame_state.k_key_press or frame_state.j_key_press \
					or frame_state.f_key_press or frame_state.d_key_press:
				scorecard.penalty(chart.note_column[i])
			break

		# Already judged in a previous frame — skip
		if scorecard.note_status[i] != Scorecard.NoteStateEnum.WAITING:
			if i == lowest_judgment_index:
				lowest_judgment_index += 1
			continue

		# Note is past its window — MISS
		if timing < lower_bound:
			scorecard.miss_note(i, chart.note_column[i])
			note_judged.emit(i, frame_state)
			lowest_judgment_index += 1
			continue

		# Note is in the hit window — check for matching key press
		if frame_state.k_key_press and chart.note_column[i] == 0:
			register_hit(compared_t, timing, i, frame_state)
		elif frame_state.j_key_press and chart.note_column[i] == 1:
			register_hit(compared_t, timing, i, frame_state)
		elif frame_state.f_key_press and chart.note_column[i] == 2:
			register_hit(compared_t, timing, i, frame_state)
		elif frame_state.d_key_press and chart.note_column[i] == 3:
			register_hit(compared_t, timing, i, frame_state)

		# Whether hit or not, stop here — can only judge one in-window note per frame
		break


func _return_to_previous_scene() -> void:
	var return_scene = _get_return_scene()
	print("[Judge] Song completed! Returning to: ", return_scene)

	var overworld_music = get_node_or_null("/root/OverworldMusic")
	if overworld_music:
		overworld_music.on_exit_rhythm_level()

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