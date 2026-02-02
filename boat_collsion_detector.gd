extends Area3D
@export_file("*.tscn") var next_scene_path: String = "res://tutorial_lake.tscn"
@export var spawn_point_name: String = "tutorial_boat_spawnpoint_a"  # Which entrance in the next scene

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.name == "Boat":
		# Use the exported variables
		BoatManager.set_transition(next_scene_path, spawn_point_name)
		body.transition_to_scene(next_scene_path)
