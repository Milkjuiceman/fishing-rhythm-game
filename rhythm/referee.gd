class_name Referee extends Node

@export var chart: Chart

@export var music_player: MusicPlayer
@export var input_hit: InputHit
@export var judge: RhythmJudge

@export var note_speed: float = 10.
@export var input_offset: float = 0.0
@export var audio_offset: float = 0.02

signal play_chart_now(chart: Chart)
signal process(frame_state: FrameState)


func _ready() -> void:
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


func _process(delta: float) -> void:
	var frame_state := FrameState.new()
	frame_state.note_speed = note_speed
	frame_state.input_offset = input_offset
	frame_state.audio_offset = audio_offset
	music_player.fill_frame_state(delta, frame_state)
	input_hit.fill_frame_state(frame_state)
	judge.process_and_fill_frame_state(frame_state)
	process.emit(frame_state)
