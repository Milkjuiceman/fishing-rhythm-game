# water_splash_spawner.gd (Godot 4)
extends Node3D

@export var splash_scene: PackedScene

@export var water_path: NodePath

# Spawn settings
@export var min_spawn_interval: float = 2.0
@export var max_spawn_interval: float = 5.0
@export var max_active_splashes: int = 5

# Timer for spawning
@onready var spawn_timer: Timer = $SpawnTimer

# Resolved Water node
@onready var water: Node3D = get_node_or_null(water_path) as Node3D

# World-space spawn rectangle (filled from _derive_bounds_from_water)
var spawn_area_min: Vector3 = Vector3(-50, 0, -50)
var spawn_area_max: Vector3 = Vector3( 50, 0,  50)

# Track active splashes
var active_splashes: Array[Node3D] = []

func _ready() -> void:
	_derive_bounds_from_water()

	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	_reset_spawn_timer()
	spawn_timer.start()

	# One immediate spawn so you can see it right away
	call_deferred("spawn_splash")

func _derive_bounds_from_water() -> void:
	if water == null:
		push_warning("water_path not set; using default spawn bounds.")
		return

	# Local AABB -> convert both corners to world space
	var aabb: AABB = (water as VisualInstance3D).get_aabb()
	var p0: Vector3 = water.to_global(aabb.position)
	var p1: Vector3 = water.to_global(aabb.position + aabb.size)

	var wy: float = water.global_transform.origin.y
	spawn_area_min = Vector3(min(p0.x, p1.x), wy, min(p0.z, p1.z))
	spawn_area_max = Vector3(max(p0.x, p1.x), wy, max(p0.z, p1.z))

func _reset_spawn_timer() -> void:
	spawn_timer.wait_time = randf_range(min_spawn_interval, max_spawn_interval)

func _on_spawn_timer_timeout() -> void:
	# Drop any freed nodes
	active_splashes = (active_splashes.filter(func(s): return is_instance_valid(s))) as Array[Node3D]

	if active_splashes.size() < max_active_splashes:
		spawn_splash()

	_reset_spawn_timer()

func spawn_splash() -> void:
	if splash_scene == null:
		push_error("No splash scene assigned to spawner!")
		return

	var rx: float = randf_range(spawn_area_min.x, spawn_area_max.x)
	var rz: float = randf_range(spawn_area_min.z, spawn_area_max.z)
	var ry: float = spawn_area_min.y  # same as water Y
	var random_pos: Vector3 = Vector3(rx, ry, rz)

	var splash := splash_scene.instantiate() as Node3D
	if splash == null:
		push_error("splash_scene root must be a Node3D/Area3D.")
		return

	add_child(splash)                   
	splash.global_position = random_pos # place in WORLD space

	if splash.has_signal("encounter_triggered"):
		splash.connect("encounter_triggered",
			Callable(self, "_on_splash_encounter_triggered").bind(splash))

	active_splashes.append(splash)

func _on_splash_encounter_triggered(splash: Node) -> void:
	active_splashes.erase(splash)
	print("Encounter triggered at: ", (splash as Node3D).global_position)
	# TODO: fishing minigame here
