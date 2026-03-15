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

@onready var start_button   = $VBoxContainer/start_button
@onready var load_button    = $VBoxContainer/load_button
@onready var options_button = $VBoxContainer/options_button
@onready var quit_button    = $VBoxContainer/quit_button

## Reference to the TitleCinematicDirector node added to this scene.
## Assign in the Inspector, or the @onready below will find it by name.
@onready var cinematic_director: TitleCinematicDirector = $TitleCinematicDirector

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

	# The cinematic director starts itself automatically in _ready().
	# Nothing extra needed here — it reads GameStateManager on startup.


# ========================================
# UI STATE MANAGEMENT
# ========================================

# Update Load Game button availability based on save file existence
func _update_load_button_state():
	if load_button:
		var save_exists = FileAccess.file_exists("user://saves/autosave.tres")
		load_button.disabled = not save_exists

		if save_exists:
			print_debug("[MainMenu] Save file found - Load Game enabled")
		else:
			print_debug("[MainMenu] No save file - Load Game disabled")


# ========================================
# BUTTON HANDLERS
# ========================================

# Start a fresh playthrough (resets all progress)
func _on_start_button_pressed():
	print_debug("[MainMenu] Start Game pressed - Starting NEW playthrough")
	GameStateManager.start_new_game()

	# Start overworld music with fade-in
	var overworld_music = get_node_or_null("/root/OverworldMusic")
	if overworld_music:
		overworld_music.start_overworld_music()

	_transition_to(GAME_SCENE)


# Load existing save file and continue playthrough
func _on_load_button_pressed():
	print_debug("[MainMenu] Load Game pressed - Continuing from save")

	# Disable buttons to prevent double-clicks
	_disable_all_buttons()

	# Attempt to load save file
	var result = GameStateManager.load_game()

	if result == OK:
		print_debug("[MainMenu] Save loaded successfully!")

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

		_transition_to(target_scene)
	else:
		# Handle load failure by starting new game
		print_debug("[MainMenu] Failed to load save file!")
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
	print_debug("[MainMenu] Quit pressed")
	_cleanup_cinematic()
	get_tree().quit()


# ========================================
# TRANSITION HELPERS
# ========================================

## Central transition point — always cleans up the cinematic before leaving.
func _transition_to(scene_path: String) -> void:
	_cleanup_cinematic()

	var screen_transition = get_node_or_null("/root/ScreenTransition")
	if screen_transition:
		screen_transition.transition_to_scene(scene_path)
	else:
		get_tree().change_scene_to_file(scene_path)


## Free the SubViewport scene before the ScreenTransition starts rendering
## so the GPU doesn't have to carry it through the fade.
func _cleanup_cinematic() -> void:
	if cinematic_director and is_instance_valid(cinematic_director):
		cinematic_director.cleanup()


# ========================================
# HELPERS
# ========================================

func _disable_all_buttons():
	if start_button:   start_button.disabled   = true
	if load_button:    load_button.disabled    = true
	if options_button: options_button.disabled = true
	if quit_button:    quit_button.disabled    = true
