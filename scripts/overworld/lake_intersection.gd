extends Node3D

@onready var spawn_points = $SpawnPoints

func _ready():
	var boat = BoatManager.load_boat_into_scene(spawn_points)
	add_child(boat)
