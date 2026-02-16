extends Node3D

# Configuration
@export var spawn_interval: float = 10.0 # Time between each spawn
@export var max_spawns: int = 1 # Max number of water Pools per Spawner
@export var rippling_water_scene: PackedScene
@export var spawn_radius: float = 100.0 # Spawn Radius
@export var spawn_height: float = 0  # Height above spawner to place them

# Tracking
var active_waters: Array = []
var spawn_timer: Timer

func _ready():
	print("Spawner ready!")
	print("Scene assigned: ", rippling_water_scene != null)
	
	# Setup timer
	spawn_timer = Timer.new()
	spawn_timer.wait_time = spawn_interval
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(spawn_timer)
	spawn_timer.start()
	print("Timer started with interval: ", spawn_interval)
	
	# Spawn initial one
	spawn_rippling_water()

func _on_spawn_timer_timeout():
	print("Timer triggered!")
	spawn_rippling_water()

func spawn_rippling_water():
	print("Attempting to spawn... Current count: ", active_waters.size())
	
	# Check if we've hit the limit
	if active_waters.size() >= max_spawns:
		print("Hit max spawns limit (", max_spawns, ")")
		return
	
	# Check if scene is assigned
	if rippling_water_scene == null:
		print("ERROR: No rippling water scene assigned!")
		return
	
	# Generate random position in a circle around spawner
	var angle = randf() * TAU
	var distance = randf() * spawn_radius
	var offset = Vector3(cos(angle) * distance, spawn_height, sin(angle) * distance)
	var spawn_pos = global_position + offset
	
	print("Spawning at position: ", spawn_pos)
	
	# Instantiate the rippling water
	var water = rippling_water_scene.instantiate()
	
	# ONLY add once using call_deferred (avoids "busy setting up children" error)
	get_parent().call_deferred("add_child", water)
	
	# Set position after it's added (deferred)
	water.set_deferred("global_position", spawn_pos)
	
	# Track it
	active_waters.append(water)
	print("Successfully spawned! Total active: ", active_waters.size())
	
	# Connect to cleanup when it's removed
	water.tree_exiting.connect(_on_water_removed.bind(water))

func _on_water_removed(water):
	print("Water removed from scene")
	active_waters.erase(water)
	print("Active waters now: ", active_waters.size())
