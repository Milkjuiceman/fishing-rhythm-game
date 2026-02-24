class_name Referee extends Node

# nodes and exports
@export var chart: Chart
@export var music_player: MusicPlayer
@export var input_hit: InputHit
@export var judge: RhythmJudge
@export var enter_prompt: Label

@export var note_speed: float = 10.
@export var input_offset: float = -0.02
@export var audio_offset: float = -0.15

# signals for high level events
signal play_chart_now(chart: Chart)
signal process(frame_state: FrameState)
signal fish_caught(performance: float)
signal fish_failed
# signal frame_updated(frame_state: FrameState)
var catchable := false

func _ready() -> void:
	if judge != null and chart != null:
		judge.load_new_chart(chart)
	if judge.progress_bar != null:
		judge.progress_bar.catch_failed.connect(_on_catch_failed)
		judge.progress_bar.catch_available.connect(_on_catch_available)

func _process(delta: float) -> void:
	var frame_state := FrameState.new()
	frame_state.note_speed = note_speed
	frame_state.input_offset = input_offset
	frame_state.audio_offset = audio_offset
	music_player.fill_frame_state(delta, frame_state)
	input_hit.fill_frame_state(frame_state)
	judge.process_and_fill_frame_state(frame_state)
	process.emit(frame_state)
	if enter_prompt.visible == true and Input.is_action_just_pressed("ui_accept"):
		_catch_fish()
	
func _on_song_finished() -> void:
	var performance = _calculate_performance()
	fish_caught.emit(performance)
	
func _on_catch_failed() -> void:
	print("[Judge]:bar depleted, ending song")
	if enter_prompt:
		enter_prompt.visible = false
	fish_failed.emit()
	
func _on_catch_available() -> void:
	catchable = true
	print("[referee]: you hooked a fish! press enter to catch early")
	if enter_prompt:
		enter_prompt.visible = true
	
func _calculate_performance():
	var bar = judge.progress_bar
	var minv = bar.min_value
	var maxv = bar.max_value
	return clamp((bar.value - minv) / (maxv - minv), 0.0, 1.0)
	
func _catch_fish() -> void:
	catchable = false
	if enter_prompt:
		enter_prompt.visible = false
	var performance = _calculate_performance()
	fish_caught.emit(performance)

	
