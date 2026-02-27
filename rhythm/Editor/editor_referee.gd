class_name EditorReferee extends Node

# nodes and exports
@export var chart: Chart
@export var music_player: MusicPlayer
@export var input_hit: InputHit
@export var judge: EditorJudge

@export var note_speed: float = 10.
@export var input_offset: float = 0.0
@export var audio_offset: float = 0.02

# signals for high level events
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
