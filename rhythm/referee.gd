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
		judge.progress_bar.catch_unavailable.connect(_on_catch_unavailable)
	fish_caught.connect(_on_fishing_finished)

func _process(delta: float) -> void:
	var frame_state := FrameState.new()
	frame_state.note_speed = note_speed
	frame_state.input_offset = input_offset
	frame_state.audio_offset = audio_offset
	music_player.fill_frame_state(delta, frame_state)
	input_hit.fill_frame_state(frame_state)
	judge.process_and_fill_frame_state(frame_state)
	process.emit(frame_state)
	if catchable == true and Input.is_action_just_pressed("ui_accept"):
		_catch_fish()
	
func _on_song_finished() -> void:
	_catch_fish()
	
func _on_catch_failed() -> void:
	print_debug("[referee]: bar depleted, ending song")
	fish_failed.emit()
	
func _on_catch_available() -> void:
	catchable = true
	if enter_prompt:
		enter_prompt.visible = true

func _on_catch_unavailable() -> void:
	catchable = false
	if enter_prompt:
		enter_prompt.visible = false
	
func _calculate_performance():
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
	
func _catch_fish() -> void:
	catchable = false
	if enter_prompt:
		enter_prompt.visible = false
	var performance = _calculate_performance()
	var rarity = _performance_to_rarity(performance)
	if rarity != "":
		InventoryManager.add_item("fish", rarity, 1)
		# print_debug("granted 1 %s fish, inventory now %s" % [rarity, InventoryManager.items])
	fish_caught.emit()
	
func _on_fishing_finished() -> void:
	var performance = _calculate_performance()
	var rarity = _performance_to_rarity(performance)
	for qid in QuestManager.get_active_quests().keys():
		var quest = QuestManager.get_quest(qid)
		# Example matching by quest description; can extend to rarity-specific quests
		if quest.desc == "catch a fish":
			QuestManager.update_progress(qid, 1)
		elif quest.desc == "catch a rare fish" and rarity in ["rare", "legendary"]:
			QuestManager.update_progress(qid, 1)
	
