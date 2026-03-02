class_name Referee
extends Node

# nodes and exports
@export var chart: Chart

@export var music_player: MusicPlayer
@export var input_hit: InputHit
@export var judge: RhythmJudge
@export var enter_prompt: Label
@export var note_speed: float = 10.
@export var input_offset: float = 0.0
@export var audio_offset: float = 0.02

# signals for high level events
signal play_chart_now(chart: Chart)
signal process(frame_state: FrameState)
signal fish_caught(performance: float)
signal fish_failed

var catchable := false


func _ready() -> void:
	print("[Referee] _ready — enter_prompt: ", enter_prompt)
	# Add to Rhythm group so PauseMenu can find us
	add_to_group("Rhythm")
	
	# Fade out overworld music when entering rhythm level
	var overworld_music = get_node_or_null("/root/OverworldMusic")
	if overworld_music:
		overworld_music.on_enter_rhythm_level()
	
	# Load offsets from PauseMenu settings if available
	var pause_menu = get_node_or_null("/root/PauseMenu")
	if pause_menu:
		var saved_audio_offset = pause_menu.get_setting("audio_offset")
		var saved_input_offset = pause_menu.get_setting("input_offset")
		if saved_audio_offset != null:
			audio_offset = saved_audio_offset
		if saved_input_offset != null:
			input_offset = saved_input_offset
	# Load chart into judge
	if judge != null and chart != null:
		judge.load_new_chart(chart)
	# Wire up progress bar signals
	if judge != null and judge.progress_bar != null:
		judge.progress_bar.catch_failed.connect(_on_catch_failed)
		judge.progress_bar.catch_available.connect(_on_catch_available)
		judge.progress_bar.catch_unavailable.connect(_on_catch_unavailable)


func _process(delta: float) -> void:
	var frame_state := FrameState.new()
	frame_state.note_speed = note_speed
	frame_state.input_offset = input_offset
	frame_state.audio_offset = audio_offset
	music_player.fill_frame_state(delta, frame_state)
	input_hit.fill_frame_state(frame_state)
	judge.process_and_fill_frame_state(frame_state)
	process.emit(frame_state)
	if catchable and frame_state.enter_key_press:
		print("[Referee] Enter pressed — catchable: true, calling _catch_fish")
		_catch_fish()


func _on_song_finished() -> void:
	var performance = _calculate_performance()
	fish_caught.emit(performance)


func _on_catch_failed() -> void:
	print("[Referee] Bar depleted, emitting fish_failed")
	fish_failed.emit()


func _on_catch_available() -> void:
	catchable = true
	print("[Referee] _on_catch_available fired — catchable is now: true")
	if enter_prompt:
		enter_prompt.visible = true
	else:
		print("[Referee] WARNING: enter_prompt is null")


func _on_catch_unavailable() -> void:
	print("[Referee] _on_catch_unavailable fired")
	catchable = false
	if enter_prompt:
		enter_prompt.visible = false


func _calculate_performance() -> float:
	var bar = judge.progress_bar
	var minv = bar.min_value
	var maxv = bar.max_value
	return clamp((bar.value - minv) / (maxv - minv), 0.0, 1.0)


func _catch_fish() -> void:
	print("[Referee] _catch_fish called — emitting fish_caught")
	catchable = false
	if enter_prompt:
		enter_prompt.visible = false
	var performance = _calculate_performance()
	fish_caught.emit(performance)
