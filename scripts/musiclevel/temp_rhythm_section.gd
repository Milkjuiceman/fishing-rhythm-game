extends Node3D
## Rhythm Level Controller
## Manages the rhythm minigame sequence including countdown and gameplay start

const COUNTDOWN_SCENE = preload("res://scenes/ui/transitions/rhythm_countdown.tscn")

@export var referee: Referee

var _countdown_instance: RhythmCountdown = null

func _ready() -> void:
	# Don't start immediately - show countdown first
	_show_countdown()
	# connect signals for when fish is caught or catch fails
	referee.fish_caught.connect(_on_fishing_finished)
	referee.fish_failed.connect(_on_fishing_failed)


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
func _on_fishing_finished(performance: float) -> void:
	# determine fish rarity based on performance
	var rarity = _determine_rarity(performance)
	# get reference to gsm
	var item_id = "lake_trout"
	# add fish w/ rarity to inventory
	GameStateManager.current_save_data.inventory.add_item(item_id, rarity, 1)
	# debug statements
	print("Reading from inventory instance:", GameStateManager.current_save_data.inventory)
	var count = GameStateManager.current_save_data.inventory.get_item_count(item_id, rarity)
	print("added: ", item_id, " | new count: ", count, " | rarity: ", rarity)
	# return player to overworld once level ends
	_return_to_overworld()
	
# called when progress bar dips below 0
func _on_fishing_failed() -> void:
	# cleanly return to overworld
	_return_to_overworld()
	
# transform performance to a rarity tier
func _determine_rarity(ratio: float) -> String:
	if ratio > 0.9:
		return "legendary"
	elif ratio > 0.7:
		return "rare"
	elif ratio > 0.4:
		return "uncommon"
	else: 
		return "common"
	
# ends rhythm level and returns player to overworld scene
func _return_to_overworld() -> void:
	set_process(false)
	referee.set_process(false)
	call_deferred("_safety_check")
	
func _safety_check() -> void:
	var return_scene: String
	if GameStateManager.pending_transition.from_scene != "":
		return_scene = GameStateManager.pending_transition.from_scene
	else: 
		return_scene = "res://scenes/overworld/terrain/tutorial_lake.tscn"
	
	ScreenTransition.transition_to_scene(return_scene)
