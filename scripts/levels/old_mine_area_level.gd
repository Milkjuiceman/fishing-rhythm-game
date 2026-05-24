extends LevelBase
## Old Mine Area Level Controller
## Extends LevelBase for streamlined level management

# ========================================
# INITIALIZATION
# ========================================

func _init():
	spawn_points_node_path = "SpawnPoints"
	initial_spawn_point_name = "mine_boat_spawnpoint_a"

# ========================================
# LEVEL LIFECYCLE HOOKS
# ========================================

func _setup_level() -> void:
	print("Old mine area loading...")
	GameStateManager.water_surface_y = 13.479164

func _post_spawn_setup() -> void:
	print("Old mine area ready! Player spawned.")
