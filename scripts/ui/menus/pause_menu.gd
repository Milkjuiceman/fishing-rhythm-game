extends CanvasLayer
## Pause Menu Controller
## Handles game pausing, settings navigation, save/load, and menu state
## Path: Project > Project Settings > Globals > AutoLoad
## Node Name: PauseMenu

# Signals for external systems to react to pause state
signal game_paused
signal game_resumed
signal settings_changed(setting_name: String, value: Variant)
signal title_screen_requested
signal game_saved
signal game_loaded

# Node references
@onready var background: ColorRect = $Background
@onready var main_panel: PanelContainer = $MainPanel
@onready var settings_panel: PanelContainer = $SettingsPanel

# Main menu button references
@onready var resume_button: Button = $MainPanel/MarginContainer/VBoxContainer/ResumeButton
@onready var settings_button: Button = $MainPanel/MarginContainer/VBoxContainer/SettingsButton
@onready var save_button: Button = $MainPanel/MarginContainer/VBoxContainer/SaveButton
@onready var load_button: Button = $MainPanel/MarginContainer/VBoxContainer/LoadButton
@onready var title_button: Button = $MainPanel/MarginContainer/VBoxContainer/TitleScreenButton
@onready var quit_button: Button = $MainPanel/MarginContainer/VBoxContainer/QuitButton

# Settings panel references (update these paths to match your scene)
@onready var master_slider: HSlider = %MasterSlider if has_node("%MasterSlider") else null
@onready var master_value: Label = %MasterValue if has_node("%MasterValue") else null
@onready var music_slider: HSlider = %MusicSlider if has_node("%MusicSlider") else null
@onready var music_value: Label = %MusicValue if has_node("%MusicValue") else null
@onready var sfx_slider: HSlider = %SFXSlider if has_node("%SFXSlider") else null
@onready var sfx_value: Label = %SFXValue if has_node("%SFXValue") else null
@onready var mouse_sens_slider: HSlider = %MouseSensSlider if has_node("%MouseSensSlider") else null
@onready var mouse_sens_value: Label = %MouseSensValue if has_node("%MouseSensValue") else null

# Checkbox references
@onready var fullscreen_check: CheckBox = %FullscreenCheck if has_node("%FullscreenCheck") else null
@onready var vsync_check: CheckBox = %VSyncCheck if has_node("%VSyncCheck") else null
@onready var show_fps_check: CheckBox = %ShowFPSCheck if has_node("%ShowFPSCheck") else null
@onready var invert_y_check: CheckBox = %InvertYCheck if has_node("%InvertYCheck") else null

# Back button
@onready var back_button: Button = %BackButton if has_node("%BackButton") else null

# State tracking
var is_paused: bool = false
var is_in_settings: bool = false
var _previous_mouse_mode: Input.MouseMode = Input.MOUSE_MODE_CAPTURED

# Settings data with defaults
var settings: Dictionary = {
	"master_volume": 80.0,
	"music_volume": 70.0,
	"sfx_volume": 100.0,
	"fullscreen": false,
	"vsync": true,
	"show_fps": false,
	"mouse_sensitivity": 5.0,
	"invert_y": false
}

# Path to settings file
const SETTINGS_PATH: String = "user://settings.cfg"

# Path to title/main menu scene
const TITLE_SCREEN_PATH: String = "res://main_menu.tscn"


func _ready() -> void:
	# Start hidden
	_hide_all()
	
	# Load saved settings
	_load_settings()
	_apply_settings_to_ui()
	_apply_settings_to_game()
	
	# Connect all buttons
	_connect_buttons()


func _connect_buttons() -> void:
	# Main menu buttons - check if already connected to avoid errors
	if resume_button and not resume_button.pressed.is_connected(_on_resume_pressed):
		resume_button.pressed.connect(_on_resume_pressed)
	if settings_button and not settings_button.pressed.is_connected(_on_settings_pressed):
		settings_button.pressed.connect(_on_settings_pressed)
	if save_button and not save_button.pressed.is_connected(_on_save_pressed):
		save_button.pressed.connect(_on_save_pressed)
	if load_button and not load_button.pressed.is_connected(_on_load_pressed):
		load_button.pressed.connect(_on_load_pressed)
	if title_button and not title_button.pressed.is_connected(_on_title_screen_pressed):
		title_button.pressed.connect(_on_title_screen_pressed)
	if quit_button and not quit_button.pressed.is_connected(_on_quit_pressed):
		quit_button.pressed.connect(_on_quit_pressed)


func _unhandled_input(event: InputEvent) -> void:
	# Toggle pause with Tab key
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_TAB:
		print("[PauseMenu] Tab key detected, toggling pause")
		if is_in_settings:
			_on_back_pressed()
		else:
			toggle_pause()
		get_viewport().set_input_as_handled()


func toggle_pause() -> void:
	if is_paused:
		resume_game()
	else:
		pause_game()


func pause_game() -> void:
	is_paused = true
	get_tree().paused = true
	
	# Store current mouse mode to restore later
	_previous_mouse_mode = Input.mouse_mode
	
	# Show menu
	background.visible = true
	main_panel.visible = true
	settings_panel.visible = false
	is_in_settings = false
	
	# Show cursor for menu navigation
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	# Focus first button for controller/keyboard navigation
	if resume_button:
		resume_button.grab_focus()
	
	game_paused.emit()


func resume_game() -> void:
	if not is_paused:
		return
	
	is_paused = false
	is_in_settings = false
	get_tree().paused = false
	
	_hide_all()
	
	# Restore previous mouse mode
	Input.mouse_mode = _previous_mouse_mode
	
	game_resumed.emit()


func _hide_all() -> void:
	background.visible = false
	main_panel.visible = false
	settings_panel.visible = false


# =============================================================================
# MAIN MENU BUTTON HANDLERS
# =============================================================================

func _on_resume_pressed() -> void:
	print("[PauseMenu] Resume pressed")
	resume_game()


func _on_save_pressed() -> void:
	print("[PauseMenu] Save Game pressed")
	_perform_save()


func _on_load_pressed() -> void:
	print("[PauseMenu] Load Game pressed")
	_perform_load()


func _on_settings_pressed() -> void:
	print("[PauseMenu] Settings pressed")
	is_in_settings = true
	main_panel.visible = false
	settings_panel.visible = true
	if back_button:
		back_button.grab_focus()


func _on_title_screen_pressed() -> void:
	print("[PauseMenu] Return to Title pressed")
	
	# Save game before going to title
	_save_game_before_exit()
	
	# Save settings before transitioning
	_save_settings()
	
	# Hide pause menu
	is_paused = false
	_hide_all()
	
	title_screen_requested.emit()
	
	# Change to title screen
	if ResourceLoader.exists(TITLE_SCREEN_PATH):
		get_tree().paused = false
		get_tree().change_scene_to_file(TITLE_SCREEN_PATH)
	else:
		push_warning("[PauseMenu] Title screen not found at: " + TITLE_SCREEN_PATH)


func _on_quit_pressed() -> void:
	print("[PauseMenu] Quit pressed")
	
	# Save game before quitting
	_save_game_before_exit()
	
	# Save settings before quitting
	_save_settings()
	
	get_tree().quit()


# =============================================================================
# SAVE/LOAD FUNCTIONALITY
# =============================================================================

func _perform_save() -> void:
	print("[PauseMenu] Performing save...")
	
	# Make sure we have a player instance
	if not GameStateManager.player_instance:
		print("[PauseMenu] ERROR: No player instance to save!")
		_show_feedback_message("No Player Found!", Color.RED)
		return
	
	# Save current player state
	GameStateManager.save_player_state(GameStateManager.player_instance)
	print("[PauseMenu] Player state saved")
	
	# Save to file
	var result = GameStateManager.save_game()
	
	if result == OK:
		print("[PauseMenu] ✅ Game saved successfully to: user://saves/autosave.tres")
		_show_feedback_message("Game Saved!", Color.GREEN)
		game_saved.emit()
	else:
		print("[PauseMenu] ❌ Failed to save game! Error code: ", result)
		_show_feedback_message("Save Failed!", Color.RED)


func _perform_load() -> void:
	print("[PauseMenu] Performing load...")
	
	# Check if save file exists
	if not FileAccess.file_exists("user://saves/autosave.tres"):
		print("[PauseMenu] ❌ No save file found!")
		_show_feedback_message("No Save File!", Color.ORANGE)
		return
	
	# Load from file
	var result = GameStateManager.load_game()
	
	if result == OK:
		print("[PauseMenu] ✅ Game loaded successfully!")
		_show_feedback_message("Game Loaded!", Color.GREEN)
		
		# Close pause menu
		resume_game()
		
		# Wait a frame then reload scene
		await get_tree().process_frame
		
		# Reload the current scene to apply loaded state
		print("[PauseMenu] Reloading scene to apply loaded state...")
		get_tree().reload_current_scene()
		
		game_loaded.emit()
	else:
		print("[PauseMenu] ❌ Failed to load game! Error code: ", result)
		_show_feedback_message("Load Failed!", Color.RED)


func _save_game_before_exit() -> void:
	# Auto-save when exiting to menu or quitting
	if GameStateManager.player_instance:
		print("[PauseMenu] Auto-saving before exit...")
		GameStateManager.save_player_state(GameStateManager.player_instance)
		GameStateManager.autosave()


func _show_feedback_message(message: String, color: Color) -> void:
	# Show feedback in console for now
	print("[PauseMenu] 💬 FEEDBACK: %s" % message)
	
	# TODO: Add a nice UI label that fades in/out
	# For now, console messages work fine for testing


# =============================================================================
# SETTINGS PANEL HANDLERS
# =============================================================================

func _on_back_pressed() -> void:
	is_in_settings = false
	settings_panel.visible = false
	main_panel.visible = true
	if settings_button:
		settings_button.grab_focus()
	
	# Save settings when leaving settings menu
	_save_settings()


# --- Audio Settings ---

func _on_master_volume_changed(value: float) -> void:
	settings["master_volume"] = value
	if master_value:
		master_value.text = "%d%%" % int(value)
	settings_changed.emit("master_volume", value)
	_apply_volume("Master", value)


func _on_music_volume_changed(value: float) -> void:
	settings["music_volume"] = value
	if music_value:
		music_value.text = "%d%%" % int(value)
	settings_changed.emit("music_volume", value)
	_apply_volume("Music", value)


func _on_sfx_volume_changed(value: float) -> void:
	settings["sfx_volume"] = value
	if sfx_value:
		sfx_value.text = "%d%%" % int(value)
	settings_changed.emit("sfx_volume", value)
	_apply_volume("SFX", value)


func _apply_volume(bus_name: String, value: float) -> void:
	var bus_idx := AudioServer.get_bus_index(bus_name)
	if bus_idx >= 0:
		# Convert percentage (0-100) to decibels
		if value <= 0:
			AudioServer.set_bus_mute(bus_idx, true)
		else:
			AudioServer.set_bus_mute(bus_idx, false)
			AudioServer.set_bus_volume_db(bus_idx, linear_to_db(value / 100.0))


# --- Display Settings ---

func _on_fullscreen_toggled(button_pressed: bool) -> void:
	settings["fullscreen"] = button_pressed
	settings_changed.emit("fullscreen", button_pressed)
	
	if button_pressed:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


func _on_vsync_toggled(button_pressed: bool) -> void:
	settings["vsync"] = button_pressed
	settings_changed.emit("vsync", button_pressed)
	
	if button_pressed:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)


func _on_show_fps_toggled(button_pressed: bool) -> void:
	settings["show_fps"] = button_pressed
	settings_changed.emit("show_fps", button_pressed)


# --- Gameplay Settings ---

func _on_mouse_sens_changed(value: float) -> void:
	settings["mouse_sensitivity"] = value
	if mouse_sens_value:
		mouse_sens_value.text = "%.1f" % value
	settings_changed.emit("mouse_sensitivity", value)


func _on_invert_y_toggled(button_pressed: bool) -> void:
	settings["invert_y"] = button_pressed
	settings_changed.emit("invert_y", button_pressed)


# =============================================================================
# SETTINGS PERSISTENCE
# =============================================================================

func _load_settings() -> void:
	var config := ConfigFile.new()
	var err := config.load(SETTINGS_PATH)
	
	if err != OK:
		# No saved settings, use defaults
		return
	
	# Load audio settings
	settings["master_volume"] = config.get_value("audio", "master_volume", settings["master_volume"])
	settings["music_volume"] = config.get_value("audio", "music_volume", settings["music_volume"])
	settings["sfx_volume"] = config.get_value("audio", "sfx_volume", settings["sfx_volume"])
	
	# Load display settings
	settings["fullscreen"] = config.get_value("display", "fullscreen", settings["fullscreen"])
	settings["vsync"] = config.get_value("display", "vsync", settings["vsync"])
	settings["show_fps"] = config.get_value("display", "show_fps", settings["show_fps"])
	
	# Load gameplay settings
	settings["mouse_sensitivity"] = config.get_value("gameplay", "mouse_sensitivity", settings["mouse_sensitivity"])
	settings["invert_y"] = config.get_value("gameplay", "invert_y", settings["invert_y"])


func _save_settings() -> void:
	var config := ConfigFile.new()
	
	# Save audio settings
	config.set_value("audio", "master_volume", settings["master_volume"])
	config.set_value("audio", "music_volume", settings["music_volume"])
	config.set_value("audio", "sfx_volume", settings["sfx_volume"])
	
	# Save display settings
	config.set_value("display", "fullscreen", settings["fullscreen"])
	config.set_value("display", "vsync", settings["vsync"])
	config.set_value("display", "show_fps", settings["show_fps"])
	
	# Save gameplay settings
	config.set_value("gameplay", "mouse_sensitivity", settings["mouse_sensitivity"])
	config.set_value("gameplay", "invert_y", settings["invert_y"])
	
	var err := config.save(SETTINGS_PATH)
	if err != OK:
		push_error("[PauseMenu] Failed to save settings: " + str(err))


func _apply_settings_to_ui() -> void:
	# Apply loaded settings to UI elements
	if master_slider:
		master_slider.value = settings["master_volume"]
	if master_value:
		master_value.text = "%d%%" % int(settings["master_volume"])
	
	if music_slider:
		music_slider.value = settings["music_volume"]
	if music_value:
		music_value.text = "%d%%" % int(settings["music_volume"])
	
	if sfx_slider:
		sfx_slider.value = settings["sfx_volume"]
	if sfx_value:
		sfx_value.text = "%d%%" % int(settings["sfx_volume"])
	
	if fullscreen_check:
		fullscreen_check.button_pressed = settings["fullscreen"]
	
	if vsync_check:
		vsync_check.button_pressed = settings["vsync"]
	
	if show_fps_check:
		show_fps_check.button_pressed = settings["show_fps"]
	
	if mouse_sens_slider:
		mouse_sens_slider.value = settings["mouse_sensitivity"]
	if mouse_sens_value:
		mouse_sens_value.text = "%.1f" % settings["mouse_sensitivity"]
	
	if invert_y_check:
		invert_y_check.button_pressed = settings["invert_y"]


func _apply_settings_to_game() -> void:
	# Apply all settings that affect the game immediately
	_apply_volume("Master", settings["master_volume"])
	_apply_volume("Music", settings["music_volume"])
	_apply_volume("SFX", settings["sfx_volume"])
	
	# Apply display settings
	if settings["fullscreen"]:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	
	if settings["vsync"]:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
