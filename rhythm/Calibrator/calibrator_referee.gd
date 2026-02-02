class_name CalibratorReferee extends Node

@export var chart: Chart

@export var music_player: CalibratorMusicPlayer
@export var input_hit: CalibratorInputHit
@export var judge: CalibratorJudge

@export var note_speed: float = 10.
@export var input_offset: float = -0.02
@export var audio_offset: float = 0.0

signal play_chart_now(chart: Chart)
signal process(frame_state: FrameState)


func _process(delta: float) -> void:
	var frame_state := FrameState.new()
	frame_state.note_speed = note_speed
	frame_state.input_offset = input_offset
	frame_state.audio_offset = audio_offset
	music_player.fill_frame_state(delta, frame_state)
	input_hit.fill_frame_state(frame_state)
	judge.process_and_fill_frame_state(frame_state)
	process.emit(frame_state)
