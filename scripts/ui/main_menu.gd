extends Control

# Path to your next scene (change this to your actual scene path)
const GAME_SCENE = "res://scenes/overworld/terrain/tutorial_lake.tscn"

func _ready():
	# Connect the buttons to their functions
	$VBoxContainer/start_button.pressed.connect(_on_start_button_pressed)
	$VBoxContainer/quit_button.pressed.connect(_on_quit_button_pressed)

func _on_start_button_pressed():
	# Change to the game scene
	get_tree().change_scene_to_file(GAME_SCENE)

func _on_quit_button_pressed():
	# Quit the game
	get_tree().quit()
