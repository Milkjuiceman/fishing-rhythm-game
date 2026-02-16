extends Area3D
@export_file("*.tscn") var next_scene_path: String = "res://scenes/overworld/terrain/lake_intersection.tscn"
@export var spawn_point_name: String = "lake_intersection_boat_spawnpoint_a"  

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.name == "Boat":
		# Use the exported variables
		BoatManager.set_transition(next_scene_path, spawn_point_name)
		body.transition_to_scene(next_scene_path)
