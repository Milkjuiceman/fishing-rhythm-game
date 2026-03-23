class_name Referee extends Node

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
signal process(frame_state: FrameState)
signal play_chart_now(chart: Chart)
signal fish_caught(performance: float, rarity: String)
signal fish_failed
signal reel_in_denied

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
		var performance = _calculate_performance()
		var rarity = _performance_to_rarity(performance)
		_catch_fish(performance, rarity)
		
func _on_judge_song_finished() -> void:
	var performance = _calculate_performance()
	var rarity = _performance_to_rarity(performance)
	_catch_fish(performance, rarity)

func _on_catch_failed() -> void:
	print_debug("[referee]: bar depleted, ending song")
	fish_failed.emit()


func _on_catch_available() -> void:
	catchable = true
	if enter_prompt:
		enter_prompt.visible = true
	else:
		print("[Referee] WARNING: enter_prompt is null")
	
	await get_tree().create_timer(5.0).timeout
	_on_catch_unavailable()
	emit_signal("reel_in_denied")
	judge.scorecard.score += 1000


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
	
func _performance_to_rarity(performance: float) -> String:
	print_debug("performance: ", performance)
	if performance >= 0.99:
		return "legendary"
	elif performance >= 0.90:
		return "rare"
	elif performance >= 0.80:
		return "uncommon"
	else: 
		return "common"
	
func _catch_fish(performance: float, rarity: String) -> void:
	print("[Referee] _catch_fish called — emitting fish_caught")
	catchable = false
	if enter_prompt:
		enter_prompt.visible = false
	if rarity != "":
		InventoryManager.add_item("fish", rarity, 1)
		# print_debug("granted 1 %s fish, inventory now %s" % [rarity, InventoryManager.items])
	fish_caught.emit(performance, rarity)
