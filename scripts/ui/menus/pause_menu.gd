extends CanvasLayer
## Pause Menu Controller
## Handles game pausing, settings navigation, save/load, and menu state
## Node Name: PauseMenu

# Signals for external systems to react to pause state
signal game_paused
signal game_resumed
signal settings_changed(setting_name: String, value: Variant)
signal title_screen_requested
signal game_saved
signal game_loaded

# Countdown scene for rhythm section resume
const COUNTDOWN_SCENE = preload("res://scenes/ui/transitions/rhythm_countdown.tscn")

# Node references
@onready var background: ColorRect = $Background
@onready var main_panel: PanelContainer = $MainPanel
@onready var settings_panel: PanelContainer = $SettingsPanel

# Main menu button references
@onready var resume_button: Button = %ResumeButton
@onready var settings_button: Button = %SettingsButton
@onready var save_button: Button = %SaveButton
@onready var load_button: Button = %LoadButton
@onready var title_button: Button = %TitleScreenButton
@onready var quit_button: Button = %QuitButton

# Settings panel references
@onready var master_slider: HSlider = %MasterSlider
@onready var master_value: Label = %MasterValue
@onready var music_slider: HSlider = %MusicSlider
@onready var music_value: Label = %MusicValue
@onready var sfx_slider: HSlider = %SFXSlider
@onready var sfx_value: Label = %SFXValue
@onready var mouse_sens_slider: HSlider = %MouseSensSlider
@onready var mouse_sens_value: Label = %MouseSensValue

# Rhythm offset sliders
@onready var audio_offset_slider: HSlider = %AudioOffsetSlider
@onready var audio_offset_value: Label = %AudioOffsetValue
@onready var input_offset_slider: HSlider = %InputOffsetSlider
@onready var input_offset_value: Label = %InputOffsetValue

# Checkbox references
@onready var fullscreen_check: CheckBox = %FullscreenCheck
@onready var vsync_check: CheckBox = %VSyncCheck
@onready var show_fps_check: CheckBox = %ShowFPSCheck
@onready var invert_y_check: CheckBox = %InvertYCheck

# Back button
@onready var back_button: Button = %BackButton

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
	"invert_y": false,
	"audio_offset": -0.02,
	"input_offset": -0.02
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


func _unhandled_input(event: InputEvent) -> void:
	# Toggle pause with Tab key
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_TAB:
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
	
	_hide_all()
	
	# Restore previous mouse mode
	Input.mouse_mode = _previous_mouse_mode
	
	# Check if we're in a rhythm section (look for Referee in Rhythm group)
	var referees = get_tree().get_nodes_in_group("Rhythm")
	if referees.size() > 0:
		# We're in rhythm section - show countdown before resuming
		_show_rhythm_countdown()
	else:
		# Normal resume - unpause immediately
		get_tree().paused = false
		game_resumed.emit()


func _show_rhythm_countdown() -> void:
	# Create countdown instance (it will handle unpausing when done)
	var countdown = COUNTDOWN_SCENE.instantiate()
	countdown.start_from_white = false  # Don't start from white, just fade in dark
	
	# Add to scene tree
	get_tree().root.add_child(countdown)
	
	# Connect to know when countdown finishes
	countdown.countdown_finished.connect(_on_rhythm_countdown_finished)
	
	# Start the countdown (game stays paused, countdown handles unpause)
	countdown.start_countdown()


func _on_rhythm_countdown_finished() -> void:
	# Countdown already unpaused the game, just emit our signal
	game_resumed.emit()


func _hide_all() -> void:
	background.visible = false
	main_panel.visible = false
	settings_panel.visible = false


# =============================================================================
# SETTINGS PANEL - Can be opened from main menu or pause menu
# =============================================================================

# Open settings panel directly (for use from main menu Options button)
func show_settings_only() -> void:
	is_in_settings = true
	background.visible = true
	main_panel.visible = false
	settings_panel.visible = true
	
	# Show cursor for menu navigation
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	if back_button:
		back_button.grab_focus()


# Close settings and return to previous state
func hide_settings() -> void:
	is_in_settings = false
	settings_panel.visible = false
	
	# If we were paused, show main panel; otherwise hide everything
	if is_paused:
		main_panel.visible = true
		if settings_button:
			settings_button.grab_focus()
	else:
		_hide_all()
	
	# Save settings when leaving
	_save_settings()


# =============================================================================
# MAIN MENU BUTTON HANDLERS
# =============================================================================

func _on_resume_pressed() -> void:
	resume_game()


func _on_save_pressed() -> void:
	_perform_save()


func _on_load_pressed() -> void:
	_perform_load()


func _on_settings_pressed() -> void:
	is_in_settings = true
	main_panel.visible = false
	settings_panel.visible = true
	if back_button:
		back_button.grab_focus()


func _on_title_screen_pressed() -> void:
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
	# Save game before quitting
	_save_game_before_exit()
	
	# Save settings before quitting
	_save_settings()
	
	get_tree().quit()


# =============================================================================
# SAVE/LOAD FUNCTIONALITY
# =============================================================================

func _perform_save() -> void:
	# Make sure we have a player instance
	if not GameStateManager.player_instance:
		push_warning("[PauseMenu] No player instance to save!")
		return
	
	# Save current player state
	GameStateManager.save_player_state(GameStateManager.player_instance)
	
	# Save to file
	var result = GameStateManager.save_game()
	
	if result == OK:
		print("[PauseMenu] Game saved successfully")
		game_saved.emit()
	else:
		push_error("[PauseMenu] Failed to save game! Error: " + str(result))


func _perform_load() -> void:
	# Check if save file exists
	if not FileAccess.file_exists("user://saves/autosave.tres"):
		push_warning("[PauseMenu] No save file found!")
		return
	
	# Load from file
	var result = GameStateManager.load_game()
	
	if result == OK:
		# Close pause menu
		resume_game()
		
		# Wait a frame then reload scene
		await get_tree().process_frame
		
		# Reload the current scene to apply loaded state
		get_tree().reload_current_scene()
		
		game_loaded.emit()
	else:
		push_error("[PauseMenu] Failed to load game! Error: " + str(result))


func _save_game_before_exit() -> void:
	# Auto-save when exiting to menu or quitting
	if GameStateManager.player_instance:
		GameStateManager.save_player_state(GameStateManager.player_instance)
		GameStateManager.autosave()


# =============================================================================
# SETTINGS PANEL HANDLERS
# =============================================================================

func _on_back_pressed() -> void:
	hide_settings()


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
	_apply_volume("Overworld Music", value)


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


# --- Rhythm Calibration Settings ---

func _on_audio_offset_changed(value: float) -> void:
	settings["audio_offset"] = value
	if audio_offset_value:
		audio_offset_value.text = "%.0f ms" % (value * 1000.0)
	settings_changed.emit("audio_offset", value)
	_apply_offsets_to_referees()


func _on_input_offset_changed(value: float) -> void:
	settings["input_offset"] = value
	if input_offset_value:
		input_offset_value.text = "%.0f ms" % (value * 1000.0)
	settings_changed.emit("input_offset", value)
	_apply_offsets_to_referees()


func _apply_offsets_to_referees() -> void:
	# Find any active referee nodes and update their offsets
	var referees = get_tree().get_nodes_in_group("Rhythm")
	for referee in referees:
		if "audio_offset" in referee:
			referee.audio_offset = settings["audio_offset"]
		if "input_offset" in referee:
			referee.input_offset = settings["input_offset"]


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
	
	# Load rhythm calibration settings
	settings["audio_offset"] = config.get_value("rhythm", "audio_offset", settings["audio_offset"])
	settings["input_offset"] = config.get_value("rhythm", "input_offset", settings["input_offset"])


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
	
	# Save rhythm calibration settings
	config.set_value("rhythm", "audio_offset", settings["audio_offset"])
	config.set_value("rhythm", "input_offset", settings["input_offset"])
	
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
	
	# Rhythm calibration settings
	if audio_offset_slider:
		audio_offset_slider.value = settings["audio_offset"]
	if audio_offset_value:
		audio_offset_value.text = "%.0f ms" % (settings["audio_offset"] * 1000.0)
	
	if input_offset_slider:
		input_offset_slider.value = settings["input_offset"]
	if input_offset_value:
		input_offset_value.text = "%.0f ms" % (settings["input_offset"] * 1000.0)


func _apply_settings_to_game() -> void:
	# Apply all settings that affect the game immediately
	_apply_volume("Master", settings["master_volume"])
	_apply_volume("Overworld Music", settings["music_volume"])
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
	
	# Apply rhythm offsets to any active referees
	_apply_offsets_to_referees()


# =============================================================================
# PUBLIC API - For external systems to interact with pause menu
# =============================================================================

func is_game_paused() -> bool:
	return is_paused


func get_setting(setting_name: String) -> Variant:
	return settings.get(setting_name, null)


func set_setting(setting_name: String, value: Variant) -> void:
	settings[setting_name] = value
	_apply_settings_to_ui()
	_save_settings()
	settings_changed.emit(setting_name, value)


func get_all_settings() -> Dictionary:
	return settings.duplicate()
