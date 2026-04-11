extends Node3D 
## Controls the rhythm fishing minigame level flow including countdown initialization and gameplay start.
## Acts as a controller between the UI countdown system, the Referee rhythm gameplay logic, 
## and the GameStateManager for inventory updates and scene transitions.
## Author: Tyler Schauermann
## Date of last update: 03/09/2026
## Designed so the countdown system and gameplay controller remain modular.
## Additional minigames or rhythm level variants could reuse this controller
## by swapping charts, countdown scenes, or reward logic.

# ========================================
# CONSTANTS AND EXPORTED VARIABLES
# ========================================

# Preloaded countdown scene used to start the rhythm gameplay
const COUNTDOWN_SCENE = preload("res://scenes/ui/transitions/rhythm_countdown.tscn")

# Reference to the Referee node
@export var referee: Referee
@export var judge: RhythmJudge

# ========================================
# RUNTIME STATE VARIABLES
# ========================================

# Stores the active countdown instance created at runtime
var _countdown_instance: RhythmCountdown = null

# ========================================
# STARTUP AND COUNTDOWN
# ========================================

# Initializes the rhythm level and connects gameplay signals
func _ready() -> void:
	_show_countdown() # Don't start level until countdown finishes
	referee.fish_caught.connect(_on_fishing_finished)
	referee.fish_failed.connect(_on_fishing_failed)

# Creates and starts the countdown before gameplay begins
func _show_countdown() -> void:
	# Creates, adds, and connects countdown instance to tree
	_countdown_instance = COUNTDOWN_SCENE.instantiate()
	add_child(_countdown_instance)
	_countdown_instance.countdown_finished.connect(_on_countdown_finished)
	
	_countdown_instance.start_countdown() # Start the countdown

# Starts the rhythm section once the countdown completes
func _on_countdown_finished() -> void:
	print("[RhythmLevel] Countdown finished, starting chart!")
	referee.play_chart_now.emit(referee.chart)


# ========================================
# FISHING RESULTS AND INVENTORY UPDATE
# ========================================

# Handles successful fishing results and awards inventory items
func _on_fishing_finished(performance: float, rarity: String) -> void:
	var item_id = "lake_trout"
		# GameStateManager.current_save_data.inventory.add_item(item_id, rarity, 1) # add fish w/ rarity to inventory
	
	# debug statements
	print("Reading from inventory instance:", GameStateManager.current_save_data.inventory)
	# var count = GameStateManager.current_save_data.inventory.get_item_count(item_id, rarity)
	# print("added: ", item_id, " | new count: ", count, " | rarity: ", rarity)

	_return_to_overworld() # return player to overworld once level ends


# Handles fishing failure when the progress bar reaches zero
func _on_fishing_failed() -> void:
	_return_to_overworld() # Hand off to return function


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


# ========================================
# LEVEL EXIT / SCENE TRANSITION
# ========================================

# Safely stops gameplay processing and begins the return transition
func _return_to_overworld() -> void:
	set_process(false)
	referee.set_process(false)
	call_deferred("_safety_check")

# Determines which scene to return to and triggers the screen transition
func _safety_check() -> void:
	var return_scene: String
	if GameStateManager.pending_transition.from_scene != "":
		return_scene = GameStateManager.pending_transition.from_scene
	else: 
		return_scene = "res://scenes/overworld/terrain/tutorial_lake.tscn"
	
	ScreenTransition.transition_to_scene(return_scene)
	
