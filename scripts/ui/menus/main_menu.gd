extends Control
## Main Menu Controller
## Handles new game creation, save file loading, options, and main menu navigation
## Manages save file validation and scene transitions with white-out effect

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
	
	# Focus the start button for keyboard/controller navigation
	if start_button:
		start_button.grab_focus()
	
	# Stop overworld music if it's playing (returning from game to title)
	var overworld_music = get_node_or_null("/root/OverworldMusic")
	if overworld_music and overworld_music.is_playing():
		overworld_music.stop()


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
	
	# Disable buttons to prevent double-clicks
	_disable_all_buttons()
	
	# Reset GameStateManager to default state
	GameStateManager.current_save_data = PlayerSaveData.new()
	GameStateManager.is_first_spawn = true
	
	# Delete existing save file to ensure clean slate
	if FileAccess.file_exists("user://saves/autosave.tres"):
		DirAccess.remove_absolute("user://saves/autosave.tres")
		print("[MainMenu] Deleted old save file for fresh start")
	
	# Start overworld music with fade-in
	var overworld_music = get_node_or_null("/root/OverworldMusic")
	if overworld_music:
		overworld_music.start_overworld_music()
	
	# Use screen transition if available
	var screen_transition = get_node_or_null("/root/ScreenTransition")
	if screen_transition:
		screen_transition.transition_to_scene(GAME_SCENE)
	else:
		# Fallback to direct scene change
		get_tree().change_scene_to_file(GAME_SCENE)

# Load existing save file and continue playthrough
func _on_load_button_pressed():
	print("[MainMenu] Load Game pressed - Continuing from save")
	
	# Disable buttons to prevent double-clicks
	_disable_all_buttons()
	
	# Attempt to load save file
	var result = GameStateManager.load_game()
	
	if result == OK:
		print("[MainMenu] Save loaded successfully!")
		
		# Start overworld music with fade-in
		var overworld_music = get_node_or_null("/root/OverworldMusic")
		if overworld_music:
			overworld_music.start_overworld_music()
		
		# Retrieve saved scene path from save data
		var saved_scene = GameStateManager.current_save_data.current_scene_path
		var target_scene = GAME_SCENE
		
		# Load saved scene if it exists
		if saved_scene != "" and ResourceLoader.exists(saved_scene):
			print("[MainMenu] Loading saved scene: ", saved_scene)
			target_scene = saved_scene
		else:
			print("[MainMenu] Saved scene not found, starting at beginning")
		
		# Use screen transition if available
		var screen_transition = get_node_or_null("/root/ScreenTransition")
		if screen_transition:
			screen_transition.transition_to_scene(target_scene)
		else:
			get_tree().change_scene_to_file(target_scene)
	else:
		# Handle load failure by starting new game
		print("[MainMenu] Failed to load save file!")
		_on_start_button_pressed()

# Open options/settings menu
func _on_options_button_pressed():
	print("[MainMenu] Options pressed - Opening settings")
	
	# Get the PauseMenu autoload and show settings panel
	var pause_menu = get_node_or_null("/root/PauseMenu")
	if pause_menu:
		pause_menu.show_settings_only()
	else:
		push_warning("[MainMenu] PauseMenu autoload not found! Make sure it's set up in Project Settings.")

# Exit the game
func _on_quit_button_pressed():
	print("[MainMenu] Quit pressed")
	get_tree().quit()


# ========================================
# HELPERS
# ========================================

func _disable_all_buttons():
	if start_button:
		start_button.disabled = true
	if load_button:
		load_button.disabled = true
	if options_button:
		options_button.disabled = true
	if quit_button:
		quit_button.disabled = true
