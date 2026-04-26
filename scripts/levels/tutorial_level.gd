extends LevelBase
## Tutorial Level Controller
## First level of the game with automatic player spawning and boat setup
## Extends LevelBase for streamlined level management

# ========================================
# INITIALIZATION
# ========================================

func _init():
	spawn_points_node_path = "SpawnPoints"
	initial_spawn_point_name = "tutorial_boat_initial_spawnpoint"

# ========================================
# LEVEL LIFECYCLE HOOKS
# ========================================

func _setup_level() -> void:
	print("Tutorial level loading...")
	GameStateManager.water_surface_y = 5.0

func _post_spawn_setup() -> void:
	print("Tutorial level ready! Player spawned successfully.")
	for obj in get_tree().get_nodes_in_group("interactable_objects"):
		if obj.has_method("assign_quest"):
			obj.assign_quest("tutorial_fishing_quest")
	if player:
		pass
