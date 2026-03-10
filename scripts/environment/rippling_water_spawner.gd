extends Node3D
## Rippling Water Spawner
## Periodically spawns rippling water fishing spots in a radius around the spawner
## Manages active water instances and respawns when removed

# ========================================
# CONFIGURATION
# ========================================

@export var spawn_interval: float = 10.0  # Time between spawns (seconds)
@export var max_spawns: int = 1  # Maximum concurrent water pools per spawner
@export var rippling_water_scene: PackedScene  # Water scene to spawn
@export var spawn_radius: float = 100.0  # Radius around spawner to place water
@export var spawn_height: float = 0.0  # Height offset above spawner

# ========================================
# VARIABLES
# ========================================

var active_waters: Array = []  # Track currently spawned water instances
var spawn_timer: Timer  # Timer for periodic spawning

# ========================================
# INITIALIZATION
# ========================================

func _ready():
	# print_debug("Spawner ready!")
	# print_debug("Scene assigned: ", rippling_water_scene != null)
	
	# Create and configure spawn timer
	spawn_timer = Timer.new()
	spawn_timer.wait_time = spawn_interval
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(spawn_timer)
	
	if GameStateManager.spawnable:
		enable_spawning()
	GameStateManager.first_quest_assigned.connect(_on_quest_assigned)

# ========================================
# SPAWNING SYSTEM
# ========================================

# Called when spawn timer completes
func _on_spawn_timer_timeout():
	# print_debug("Timer triggered!")
	spawn_rippling_water()

# Spawn a new rippling water instance at random position
func spawn_rippling_water():
	#print_debug("Attempting to spawn... Current count: ", active_waters.size())
	
	# Enforce max spawn limit
	if active_waters.size() >= max_spawns:
		#print_debug("Hit max spawns limit (", max_spawns, ")")
		return
	
	# Validate scene reference
	if rippling_water_scene == null:
		#print_debug("ERROR: No rippling water scene assigned!")
		return
	
	# Calculate random position within spawn radius
	var angle = randf() * TAU
	var distance = randf() * spawn_radius
	var offset = Vector3(cos(angle) * distance, spawn_height, sin(angle) * distance)
	var spawn_pos = global_position + offset
	
	# print_debug("Spawning at position: ", spawn_pos)
	
	# Create new water instance
	var water = rippling_water_scene.instantiate()
	
	# Add to scene tree (deferred to avoid threading issues)
	get_parent().call_deferred("add_child", water)
	
	# Set spawn position (deferred to ensure node is ready)
	water.set_deferred("global_position", spawn_pos)
	
	# Add to tracking array
	active_waters.append(water)
	#print_debug("Successfully spawned! Total active: ", active_waters.size())
	
	# Connect cleanup signal for when water is removed
	water.tree_exiting.connect(_on_water_removed.bind(water))

# ========================================
# CLEANUP
# ========================================

# Called when a water instance is removed from the scene
func _on_water_removed(water):
	# print_debug("Water removed from scene")
	active_waters.erase(water)
	# print_debug("Active waters now: ", active_waters.size())
	
func _on_quest_assigned():
	enable_spawning()

func enable_spawning():
	if not spawn_timer.is_stopped():
		return  # already active
	spawn_timer.start()
	spawn_rippling_water()

func disable_spawning():
	spawn_timer.stop()
