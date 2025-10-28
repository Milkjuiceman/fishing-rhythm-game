extends Node

@export var chart: Chart

@export var music_player: MusicPlayer
#@export var mouse_input: MouseInput
@export var judge: Judge

@export var speed: float = 1.
@export var input_offset: float = -0.02
@export var audio_offset: float = -0.02

signal play_chart_now(chart: Chart)
signal process(frame_state: FrameState)


func _process(delta: float) -> void:
	var frame_state := FrameState.new()
	frame_state.speed = speed
	frame_state.input_offset = input_offset
	frame_state.audio_offset = audio_offset
	music_player.fill_frame_state(delta, frame_state)
	#mouse_input.fill_frame_state(frame_state)
	judge.process_and_fill_frame_state(frame_state)
	process.emit(frame_state)
