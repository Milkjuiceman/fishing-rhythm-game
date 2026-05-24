extends LevelBase
## Delta Area Level Controller
## Extends LevelBase for streamlined level management

# ========================================
# INITIALIZATION
# ========================================

func _init():
	spawn_points_node_path = "SpawnPoints"
	initial_spawn_point_name = "delta_boat_spawnpoint_a"

# ========================================
# LEVEL LIFECYCLE HOOKS
# ========================================

func _setup_level() -> void:
	print("Delta area loading...")
	# Set water_surface_y to match your delta water mesh height
	GameStateManager.water_surface_y = -6.488

func _post_spawn_setup() -> void:
	print("Delta area ready! Player spawned.")
