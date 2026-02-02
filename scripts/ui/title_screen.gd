extends CanvasLayer
## Title Screen Controller
## Displays game title overlay on top of the overworld scene
## Play button fades out the title and enables gameplay

signal play_pressed
signal title_hidden

var background: ColorRect
var title_container: VBoxContainer
var play_button: Button
var animation_player: AnimationPlayer

var is_title_active: bool = true


func _ready() -> void:
	# Get node references
	background = $Background
	title_container = $TitleContainer
	play_button = $TitleContainer/PlayButton
	animation_player = $AnimationPlayer
	
	# Title screen is visible and game is paused at start
	show_title()
	
	# Connect play button
	if play_button:
		play_button.pressed.connect(_on_play_pressed)
		play_button.grab_focus()


func _input(event: InputEvent) -> void:
	# Allow Enter/Space to start game when title is active
	if is_title_active:
		if event.is_action_pressed("ui_accept"):
			_on_play_pressed()
			get_viewport().set_input_as_handled()


func show_title() -> void:
	is_title_active = true
	visible = true
	
	if background:
		background.visible = true
	if title_container:
		title_container.visible = true
	
	# Pause the game while on title screen
	get_tree().paused = true
	
	# Show cursor for menu
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	# Reset opacity for fade
	if background:
		background.modulate.a = 1.0
	if title_container:
		title_container.modulate.a = 1.0
	
	if play_button:
		play_button.grab_focus()


func hide_title() -> void:
	is_title_active = false
	
	# Manual fade out
	await _fade_out_manual()
	
	visible = false
	
	# Unpause the game
	get_tree().paused = false
	
	# Capture mouse for gameplay
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	title_hidden.emit()


func _fade_out_manual() -> void:
	var tween = create_tween()
	tween.set_parallel(true)
	if background:
		tween.tween_property(background, "modulate:a", 0.0, 0.8).set_ease(Tween.EASE_IN)
	if title_container:
		tween.tween_property(title_container, "modulate:a", 0.0, 0.6).set_ease(Tween.EASE_IN)
	await tween.finished


func _on_play_pressed() -> void:
	if not is_title_active:
		return
	
	play_pressed.emit()
	hide_title()
