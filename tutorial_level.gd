extends Node3D

@onready var spawn_points = $SpawnPoints

func _ready():
	# Check if this is the first scene (boat hasn't been created yet)
	if BoatManager.boat_instance == null:
		# First time - set initial spawn position
		var initial_spawn = $SpawnPoints/tutorial_boat_initial_spawnpoint
		BoatManager.boat_position = initial_spawn.global_transform.origin
		BoatManager.boat_rotation = Vector3(0, initial_spawn.rotation.y, 0)
	
	# Load the boat into this scene
	var boat = BoatManager.load_boat_into_scene(spawn_points)
	add_child(boat)
