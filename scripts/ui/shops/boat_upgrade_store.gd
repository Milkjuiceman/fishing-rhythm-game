extends Control
## Boat Upgrade Shop
## Handles boat selection, purchasing (future), and switching between boat types
## Uses GameStateManager for persistent boat changes across scenes

# ========================================
# SIGNALS
# ========================================

signal shop_closed

# ========================================
# VARIABLES
# ========================================

# Boat catalog - can be moved to JSON later for easier expansion
var available_boats: Array[Dictionary] = []

# ========================================
# INITIALIZATION
# ========================================

func _ready() -> void:
	# Load boat catalog data
	_setup_boat_catalog()
	
	# Allow shop to function while game is paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Show mouse cursor for UI interaction
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# Connect UI button signals
	_setup_ui()

# ========================================
# SETUP METHODS
# ========================================

# Define available boats with their properties
func _setup_boat_catalog() -> void:
	available_boats = [
		{
			"name": "Small Boat",
			"scene_path": "res://scenes/overworld/boats/boat.tscn",
			"description": "Fast and nimble",
			"price": 0
		},
		{
			"name": "Big Boat",
			"scene_path": "res://scenes/overworld/boats/boatBig.tscn",
			"description": "Powerful but slower",
			"price": 100
		}
	]

# Connect button signals to their handlers
func _setup_ui() -> void:
	var boat_button = $VBoxContainer/Boat
	var big_boat_button = $VBoxContainer/BigBoat
	var back_button = $VBoxContainer/Back
	
	if boat_button:
		boat_button.pressed.connect(_on_boat_selected.bind(0))
	if big_boat_button:
		big_boat_button.pressed.connect(_on_boat_selected.bind(1))
	if back_button:
		back_button.pressed.connect(_on_back_pressed)

# ========================================
# BUTTON HANDLERS
# ========================================

# Handle boat selection by index
func _on_boat_selected(boat_index: int) -> void:
	# Validate boat index
	if boat_index < 0 or boat_index >= available_boats.size():
		push_error("Invalid boat index: %d" % boat_index)
		return
	
	var boat_entry = available_boats[boat_index]
	print("%s selected!" % boat_entry["name"])
	
	# TODO: Add currency check when economy system is implemented
	# if GameStateManager.current_save_data.currency < boat_entry["price"]:
	#     show_insufficient_funds_message()
	#     return
	
	# Perform boat switch
	_switch_to_boat(boat_entry["scene_path"])

# Handle back button - close shop without changes
func _on_back_pressed() -> void:
	close_shop()

# ========================================
# BOAT SWITCHING
# ========================================

# Switch player's current boat to selected type
func _switch_to_boat(boat_scene_path: String) -> void:
	# Get current player instance
	var player = GameStateManager.player_instance
	
	if not player:
		push_error("No player instance found!")
		return
	
	# Reposition player at designated spawn point
	var main_scene = get_tree().current_scene
	var spawn_point = main_scene.get_node_or_null("SpawnPoints/tutorial_boat_upgrade_spawnpoint")
	
	if spawn_point:
		player.global_position = spawn_point.global_position
		player.rotation.y = spawn_point.rotation.y
	
	# Use GameStateManager to switch boat (handles cleanup and persistence)
	await GameStateManager.switch_boat(boat_scene_path, player)
	
	# Return to gameplay
	close_shop()

# ========================================
# SHOP CONTROL
# ========================================

# Close shop UI and return to gameplay
func close_shop() -> void:
	# Restore captured mouse for gameplay
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# Emit signal for cleanup
	shop_closed.emit()
