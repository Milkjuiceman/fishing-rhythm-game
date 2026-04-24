extends Node3D

@export var referee: EditorReferee
@export var judge: EditorJudge
@onready var snapper = %"Beat Grid Snapper" # Adjust paths as needed
@onready var note_holder = %Note_Holder # Adjust paths as needed
@export var editor_fallback_chart: Chart

func _ready() -> void:
	var active_chart: Chart = null
	var is_testing_mode: bool = false

	# 1. Check if we came from the Menu (GameStateManager)
	if GameStateManager.current_selected_chart != null:
		active_chart = GameStateManager.current_selected_chart
		is_testing_mode = GameStateManager.editor_testing_mode
	
	if editor_fallback_chart != null:
		active_chart = editor_fallback_chart
		is_testing_mode = false

	if active_chart:
		_synchronize_all_systems.call_deferred(active_chart, true)
	else:
		push_error("[Editor] No chart found in GameStateManager OR Inspector!")

func _synchronize_all_systems(chart: Chart, test_mode: bool) -> void:
	# Synchronize all nodes
	referee.chart = chart
	snapper.chart = chart
	note_holder.chart = chart
	note_holder.align_notes()

	# Apply data to Judge BEFORE starting
	if judge:
		judge.load_new_chart(chart)
		judge.testing = test_mode
		judge.start = 0.0

	# Pull length from the track sub-resource
	if chart.track and chart.track.song_length > 0:
		judge.finish = chart.track.song_length
	else:
		judge.finish = 60.0 # 5min fallback

	# 2. TRIGGER THE START
	judge.start_session()

	# 3. PLAY AUDIO
	referee.play_chart_now.emit(chart)
