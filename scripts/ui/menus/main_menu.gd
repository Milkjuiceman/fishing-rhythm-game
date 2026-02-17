extends Control
## Main Menu Controller
## Handles new game creation, save file loading, and main menu navigation
## Manages save file validation and scene transitions

# ========================================
# CONSTANTS
# ========================================

# Path to the first game scene
const GAME_SCENE = "res://scenes/overworld/terrain/tutorial_lake.tscn"

# ========================================
# NODE REFERENCES
# ========================================

@onready var start_button = $VBoxContainer/start_button
@onready var load_button = $VBoxContainer/load_button
@onready var options_button = $VBoxContainer/options_button
@onready var quit_button = $VBoxContainer/quit_button

# ========================================
# INITIALIZATION
# ========================================

func _ready():
	# Connect button signals to handlers
	if start_button:
		start_button.pressed.connect(_on_start_button_pressed)
	if load_button:
		load_button.pressed.connect(_on_load_button_pressed)
	if options_button:
		options_button.pressed.connect(_on_options_button_pressed)
	if quit_button:
		quit_button.pressed.connect(_on_quit_button_pressed)
	
	# Enable/disable Load button based on save file existence
	_update_load_button_state()

# ========================================
# UI STATE MANAGEMENT
# ========================================

# Update Load Game button availability based on save file existence
func _update_load_button_state():
	if load_button:
		var save_exists = FileAccess.file_exists("user://saves/autosave.tres")
		load_button.disabled = not save_exists
		
		if save_exists:
			print("[MainMenu] Save file found - Load Game enabled")
		else:
			print("[MainMenu] No save file - Load Game disabled")

# ========================================
# BUTTON HANDLERS
# ========================================

# Start a fresh playthrough (resets all progress)
func _on_start_button_pressed():
	print("[MainMenu] Start Game pressed - Starting NEW playthrough")
	
	# Reset GameStateManager to default state
	GameStateManager.current_save_data = PlayerSaveData.new()
	GameStateManager.is_first_spawn = true
	
	# Delete existing save file to ensure clean slate
	if FileAccess.file_exists("user://saves/autosave.tres"):
		DirAccess.remove_absolute("user://saves/autosave.tres")
		print("[MainMenu] Deleted old save file for fresh start")
	
	# Begin new game at starting scene
	get_tree().change_scene_to_file(GAME_SCENE)

# Load existing save file and continue playthrough
func _on_load_button_pressed():
	print("[MainMenu] Load Game pressed - Continuing from save")
	
	# Attempt to load save file
	var result = GameStateManager.load_game()
	
	if result == OK:
		print("[MainMenu] Save loaded successfully!")
		
		# Retrieve saved scene path from save data
		var saved_scene = GameStateManager.current_save_data.current_scene_path
		
		# Load saved scene if it exists
		if saved_scene != "" and ResourceLoader.exists(saved_scene):
			print("[MainMenu] Loading saved scene: ", saved_scene)
			get_tree().change_scene_to_file(saved_scene)
		else:
			# Fallback to starting scene if saved scene is missing
			print("[MainMenu] Saved scene not found, starting at beginning")
			get_tree().change_scene_to_file(GAME_SCENE)
	else:
		# Handle load failure by starting new game
		print("[MainMenu] Failed to load save file!")
		_on_start_button_pressed()

# Open options menu (placeholder for future implementation)
func _on_options_button_pressed():
	print("[MainMenu] Options pressed")
	# TODO: Open options menu scene or panel

# Exit the game
func _on_quit_button_pressed():
	print("[MainMenu] Quit pressed")
	get_tree().quit()
