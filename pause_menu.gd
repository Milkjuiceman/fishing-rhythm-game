# Written by Colin Totten 
# Initial Date: 11/6/2025
#

extends Control

@onready var animation_player: AnimationPlayer = %AnimationPlayer
@onready var panel_container: PanelContainer = %PanelContainer
@onready var vbox_container: VBoxContainer = %VBoxContainer

# Spacing between menu buttons 
const BUTTON_SPACING: int = 100

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	animation_player.play("RESET")
	hide()
	vbox_container.add_theme_constant_override("separation", BUTTON_SPACING)

# Resumes the game and hides the pause menu
func resume() -> void:
	get_tree().paused = false
	animation_player.play_backwards("blur")
	hide()

# Pauses the game and shows the pause menu
func pause() -> void:
	get_tree().paused = true
	animation_player.play("blur")
	show()

# Handles escape key input
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if get_tree().paused:
			resume()
		else:
			pause()

func _on_resume_pressed() -> void:
	resume()

func _on_restart_pressed() -> void:
	resume()
	get_tree().reload_current_scene()

func _on_quit_pressed() -> void:
	get_tree().quit()
