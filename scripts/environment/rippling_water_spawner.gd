extends Node3D
## Rippling Water Spawner
## Periodically spawns rippling water fishing spots in a radius around the spawner.
## Features:
##   - Quest gating (require_quest_id)
##   - Fish-catch stop condition (stop_when_fish_id)
##   - Spawn delay after returning from rhythm level
##   - Optional lifetime: water disappears after a set duration
##   - Collision checking: repositions water if it spawns inside another object,
##     while IGNORING the lake water mesh (identified by group "water_body")
## Author: Tyler Schauermann
## Date of last update: 04/22/2026

# ========================================
# CONFIGURATION
# ========================================
@export var spawn_interval: float = 10.0
@export var max_spawns: int = 1
@export var rippling_water_scene: PackedScene
@export var spawn_radius: float = 100.0
@export var spawn_height: float = 4.4

# ========================================
# SPAWN DELAY
# ========================================

## How long to wait before spawning after scene load or respawn.
## Prevents water from appearing on top of the player immediately on return.
@export var spawn_delay: float = 3.0

# ========================================
# LIFETIME
# ========================================

## If true, spawned water disappears after `lifetime` seconds.
@export var use_lifetime: bool = false

## Seconds before the water disappears (only used if use_lifetime = true).
@export var lifetime: float = 30.0

# ========================================
# COLLISION CHECKING
# ========================================

## How many times to retry finding a clear spawn position before giving up.
@export var max_placement_attempts: int = 10

## Sphere radius used to check for overlapping objects at the candidate position.
@export var placement_check_radius: float = 3.0

## Physics layers to check. Should include your terrain/environment layer (default: 1).
@export_flags_3d_physics var placement_check_mask: int = 1

# ========================================
# QUEST GATING
# ========================================

## If set, this spawner will not activate until the given quest ID has started.
## If the quest already started (e.g. after returning from a rhythm level),
## the spawner enables immediately on _ready.
@export var require_quest_id: String = ""

@export var spawn_once: bool = false
@export var spawn_immediately: bool = true

# ========================================
# FISH-CATCH STOP CONDITION
# ========================================

## Spawning stops permanently once this fish_id is caught.
@export var stop_when_fish_id: String = ""

# ========================================
# RHYTHM LEVEL CONFIGURATION
# ========================================

@export var rhythm_levels: Array[RhythmLevelEntry] = []

# ========================================
# RUNTIME STATE
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

	# Stop condition — check immediately in case fish was already caught before reload
	if stop_when_fish_id != "":
		if InventoryManager.has_caught_fish(stop_when_fish_id):
			return  # Already caught — never spawn
		InventoryManager.fish_caught.connect(_on_fish_caught)

	if require_quest_id != "":
		# Check if the quest already started (e.g. we returned from a rhythm level)
		var quest_state = QuestManager.get_quest_state(require_quest_id)
		if quest_state != QuestManager.states.NOT_STARTED:
			# Quest already in progress — enable now
			_delayed_enable()
		else:
			# Quest hasn't started yet — wait for the signal
			QuestManager.quest_started.connect(_on_quest_started)
	else:
		_delayed_enable()

# ========================================
# QUEST GATING
# ========================================

func _on_quest_started(quest_id: String) -> void:
	if quest_id == require_quest_id:
		QuestManager.quest_started.disconnect(_on_quest_started)
		if stop_when_fish_id != "" and InventoryManager.has_caught_fish(stop_when_fish_id):
			return
		_delayed_enable()

# ========================================
# SPAWN DELAY
# ========================================

func _delayed_enable() -> void:
	if spawn_delay <= 0.0:
		enable_spawning()
		return
	var t = Timer.new()
	t.wait_time = spawn_delay
	t.one_shot = true
	add_child(t)
	t.timeout.connect(func():
		t.queue_free()
		enable_spawning()
	)
	t.start()

# ========================================
# FISH-CATCH STOP CONDITION
# ========================================

func _on_fish_caught(fish_id: String, _count: int) -> void:
	if fish_id == stop_when_fish_id:
		InventoryManager.fish_caught.disconnect(_on_fish_caught)
		_kill_all_active_waters()
		disable_spawning()

func _kill_all_active_waters() -> void:
	for water in active_waters.duplicate():
		if is_instance_valid(water):
			water.queue_free()
	active_waters.clear()

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
			"[RipplingWaterSpawner] Rhythm level chances on '%s' add up to %.1f%% — should be 100%%." % [name, total]
		)

# ========================================
# SPAWNING
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

	var spawn_pos = _find_clear_spawn_position()
	if spawn_pos == Vector3.ZERO:
		push_warning("[RipplingWaterSpawner] Could not find a clear spawn position after %d attempts." % max_placement_attempts)
		return

	var chosen_level := _pick_rhythm_level()
	var water = rippling_water_scene.instantiate()

	if chosen_level != null and water.has_method("set_rhythm_level"):
		water.set_rhythm_level(chosen_level)

	get_parent().call_deferred("add_child", water)
	water.set_deferred("global_position", spawn_pos)

	active_waters.append(water)
	water.tree_exiting.connect(_on_water_removed.bind(water))

	if use_lifetime and lifetime > 0.0:
		_start_lifetime_timer(water)

# ========================================
# COLLISION-SAFE PLACEMENT
# ========================================

func _find_clear_spawn_position() -> Vector3:
	var space_state = get_world_3d().direct_space_state

	var shape = SphereShape3D.new()
	shape.radius = placement_check_radius

	var params = PhysicsShapeQueryParameters3D.new()
	params.shape = shape
	params.collision_mask = placement_check_mask

	for _attempt in range(max_placement_attempts):
		var angle = randf() * TAU
		var distance = randf() * spawn_radius
		var offset = Vector3(cos(angle) * distance, 0, sin(angle) * distance)
		var candidate = global_position + offset
		candidate.y = spawn_height

		params.transform = Transform3D(Basis(), candidate)
		var results = space_state.intersect_shape(params)

		var blocked := false
		for hit in results:
			var collider = hit.get("collider", null)
			if collider and not collider.is_in_group("water_body"):
				blocked = true
				break

		if not blocked:
			return candidate

	return Vector3.ZERO

# ========================================
# LIFETIME
# ========================================

func _start_lifetime_timer(water: Node3D) -> void:
	var t = Timer.new()
	t.wait_time = lifetime
	t.one_shot = true
	add_child(t)
	t.timeout.connect(func():
		t.queue_free()
		if is_instance_valid(water) and water.is_inside_tree():
			water.queue_free()
	)
	t.start()

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
# CLEANUP / RESPAWN
# ========================================

func _on_water_removed(water):
	active_waters.erase(water)

	if spawn_once:
		disable_spawning()
		return

	if not _spawning_enabled:
		return

	var wait = max(spawn_delay, 1.0)
	var t = Timer.new()
	t.wait_time = wait
	t.one_shot = true
	add_child(t)
	t.timeout.connect(func():
		t.queue_free()
		spawn_rippling_water()
	)
	t.start()

func enable_spawning():
	_spawning_enabled = true
	spawn_timer.start()
	if spawn_immediately:
		call_deferred("spawn_rippling_water")

func disable_spawning():
	_spawning_enabled = false
	spawn_timer.stop()
