extends Node3D
## Rhythm Level Controller
## Manages the rhythm minigame sequence including countdown and gameplay start

const COUNTDOWN_SCENE = preload("res://scenes/ui/transitions/rhythm_countdown.tscn")

@export var referee: Referee
@export var judge: RhythmJudge

var _countdown_instance: RhythmCountdown = null

func _ready() -> void:
		# connect signals for when fish is caught or catch fails
	referee.fish_caught.connect(_on_fishing_finished)
	referee.fish_failed.connect(_on_fishing_failed)
	if judge != null: 
		judge.song_finished.connect(_on_song_finished)
	_show_countdown()
	
func _show_countdown() -> void:
	# Create countdown instance
	_countdown_instance = COUNTDOWN_SCENE.instantiate()
	add_child(_countdown_instance)
	# Connect to countdown finished signal
	_countdown_instance.countdown_finished.connect(_on_countdown_finished)
	# Start the countdown
	_countdown_instance.start_countdown()
	
func _on_countdown_finished() -> void:
	# Countdown is done, start the rhythm gameplay
	print("[RhythmLevel] Countdown finished, starting chart!")
	referee.play_chart_now.emit(referee.chart)
	
# called when player hooks a fish
func _on_fishing_finished(_performance: float, _rarity: String) -> void:
	#print_debug("%f: %s" % performance, rarity)
	for qid in QuestManager.get_active_quests().keys():
		var quest = QuestManager.get_quest(qid)
		if quest.desc == "catch a fish":
			QuestManager.update_progress(qid, 1)
	_return_to_overworld()
	
# called when progress bar dips below 0
func _on_fishing_failed() -> void:
	# cleanly return to overworld
	_return_to_overworld()
	
func _on_song_finished() -> void:
	# cleanly return to overworld
	_return_to_overworld()
	
# ends rhythm level and returns player to overworld scene
func _return_to_overworld() -> void:
	set_process(false)
	referee.set_process(false)
	call_deferred("_exit_rhythm_scene")

func _exit_rhythm_scene() -> void:
	print("[RhythmLevel] Returning to overworld")
	get_tree().change_scene_to_file("res://scenes/overworld/terrain/tutorial_lake.tscn")
