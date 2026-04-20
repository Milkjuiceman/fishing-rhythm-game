extends Node3D
## Rippling Water Spawner
## Periodically spawns rippling water fishing spots in a radius around the spawner
## Manages active water instances and respawns when removed

# ========================================
# CONFIGURATION
# ========================================
@export var spawn_interval: float = 10.0
@export var max_spawns: int = 1
@export var rippling_water_scene: PackedScene
@export var spawn_radius: float = 100.0
@export var spawn_height: float = 4.4

# ========================================
# QUEST GATING
# ========================================

## If set, this spawner will not activate until the given quest ID has started.
@export var require_quest_id: String = ""

## If true, the water will never respawn after it is removed.
@export var spawn_once: bool = false

## If true, spawns one water immediately when enabled rather than waiting for the timer.
@export var spawn_immediately: bool = true

# ========================================
# RHYTHM LEVEL CONFIGURATION
# ========================================

@export var rhythm_levels: Array[RhythmLevelEntry] = []

# ========================================
# VARIABLES
# ========================================
var active_waters: Array = []
var spawn_timer: Timer
var _spawning_enabled: bool = false

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

	if require_quest_id != "":
		QuestManager.quest_started.connect(_on_quest_started)
	else:
		enable_spawning()

# ========================================
# QUEST GATING
# ========================================

func _on_quest_started(quest_id: String) -> void:
	if quest_id == require_quest_id:
		QuestManager.quest_started.disconnect(_on_quest_started)
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
	if not _spawning_enabled:
		return

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

	if spawn_once:
		disable_spawning()
		return

	# Use a one-shot Timer node instead of a chained signal to avoid
	# Godot 4 issues with connecting to a timer's timeout mid-frame
	var respawn_timer = Timer.new()
	respawn_timer.wait_time = 1.0
	respawn_timer.one_shot = true
	add_child(respawn_timer)
	respawn_timer.timeout.connect(_on_respawn_timer_done.bind(respawn_timer))
	respawn_timer.start()

func _on_respawn_timer_done(respawn_timer: Timer) -> void:
	respawn_timer.queue_free()
	spawn_rippling_water()

func enable_spawning():
	_spawning_enabled = true
	spawn_timer.start()
	if spawn_immediately:
		call_deferred("spawn_rippling_water")

func disable_spawning():
	_spawning_enabled = false
	spawn_timer.stop()
