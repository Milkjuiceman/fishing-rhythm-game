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
@export var spawn_height: float = 4.4  # Absolute Y coordinate for spawns

# ========================================
# RHYTHM LEVEL CONFIGURATION
# ========================================

## One entry per rhythm level this spawner can send the player to.
## Set the scene path and chance (0-100). All chances should add up to 100.
@export var rhythm_levels: Array[RhythmLevelEntry] = []

# ========================================
# VARIABLES
# ========================================
var active_waters: Array = []  # Track currently spawned water instances
var spawn_timer: Timer  # Timer for periodic spawning

# ========================================
# INITIALIZATION
# ========================================
func _ready():
	_validate_rhythm_levels()

	spawn_timer = Timer.new()
	spawn_timer.wait_time = spawn_interval
	spawn_timer.one_shot = false
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(spawn_timer)

	enable_spawning()

# ========================================
# VALIDATION
# ========================================

func _validate_rhythm_levels() -> void:
	if rhythm_levels.is_empty():
		push_warning("[RipplingWaterSpawner] No rhythm levels configured on %s." % name)
		return

	var total: float = 0.0
	for entry in rhythm_levels:
		total += entry.chance

	if not is_equal_approx(total, 100.0):
		push_warning(
			"[RipplingWaterSpawner] Rhythm level chances on '%s' add up to %.1f%% — they should add up to 100%%." % [name, total]
		)

# ========================================
# SPAWNING SYSTEM
# ========================================

func _on_spawn_timer_timeout():
	spawn_rippling_water()

func spawn_rippling_water():
	if active_waters.size() >= max_spawns:
		return

	if rippling_water_scene == null:
		return

	var chosen_level := _pick_rhythm_level()

	var angle = randf() * TAU
	var distance = randf() * spawn_radius
	var offset = Vector3(cos(angle) * distance, 0, sin(angle) * distance)
	var spawn_pos = global_position + offset
	spawn_pos.y = spawn_height

	var water = rippling_water_scene.instantiate()

	if chosen_level != null and water.has_method("set_rhythm_level"):
		water.set_rhythm_level(chosen_level)

	get_parent().call_deferred("add_child", water)
	water.set_deferred("global_position", spawn_pos)

	active_waters.append(water)
	water.tree_exiting.connect(_on_water_removed.bind(water))

# ========================================
# RHYTHM LEVEL SELECTION
# ========================================

func _pick_rhythm_level() -> RhythmLevelEntry:
	if rhythm_levels.is_empty():
		return null

	var roll := randf() * 100.0
	var cumulative: float = 0.0
	for entry in rhythm_levels:
		cumulative += entry.chance
		if roll < cumulative:
			return entry

	return rhythm_levels[-1]

# ========================================
# CLEANUP
# ========================================

func _on_water_removed(water):
	active_waters.erase(water)
	get_tree().create_timer(1.0).timeout.connect(spawn_rippling_water)

func enable_spawning():
	spawn_timer.start()
	call_deferred("spawn_rippling_water")

func disable_spawning():
	spawn_timer.stop()
