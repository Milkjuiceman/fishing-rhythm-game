extends Node3D

@export var referee: Referee;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# play the chart
	referee.play_chart_now.emit(referee.chart);
	# connect signals for when fish is caught or catch fails
	referee.fish_caught.connect(_on_fishing_finished)
	referee.fish_failed.connect(_on_fishing_failed)
	
# called when player hooks a fish
func _on_fishing_finished(performance: float) -> void:
	# determine fish rarity based on performance
	var rarity = _determine_rarity(performance)
	# get reference to gsm
	var gsm = get_node("/root/GameStateManager")
	var item_id = "lake_trout"
	# add fish w/ rarity to inventory
	gsm.current_save_data.inventory.add_item(item_id, rarity, 1)
	# debug statements
	print("Reading from inventory instance:", gsm.current_save_data.inventory)
	var count = gsm.current_save_data.inventory.get_item_count(item_id, rarity)
	print("added: ", item_id, " | new count: ", count)
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
	var gsm = get_node("/root/GameStateManager")
	if gsm.pending_transition.from_scene != "":
		return_scene = gsm.pending_transition.from_scene
	else: 
		return_scene = "res://scenes/overworld/terrain/tutorial_lake.tscn"
	get_tree().change_scene_to_file(return_scene)
	
