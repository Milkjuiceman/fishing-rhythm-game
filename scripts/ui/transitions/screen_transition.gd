extends CanvasLayer
## Screen Transition Manager
## Handles fade-to-white and fade-from-white transitions between scenes
## Node Name: ScreenTransition

signal transition_started
signal transition_midpoint  # Emitted when fully white, before loading new scene
signal transition_completed

@onready var overlay: ColorRect = $Overlay

# Transition settings
@export var fade_out_duration: float = 0.4  # Time to fade TO white
@export var fade_in_duration: float = 0.6   # Time to fade FROM white
@export var hold_duration: float = 0.15     # Time to hold on white

# Transition color (white by default)
@export var transition_color: Color = Color(1.0, 1.0, 1.0, 1.0)

var _is_transitioning: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Start fully transparent
	overlay.color = transition_color
	overlay.modulate.a = 0.0
	overlay.visible = true
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE


# Transition to a new scene with fade-out, load, fade-in
func transition_to_scene(scene_path: String, custom_fade_out: float = -1.0, custom_fade_in: float = -1.0) -> void:
	if _is_transitioning:
		push_warning("[ScreenTransition] Already transitioning!")
		return
	
	if not ResourceLoader.exists(scene_path):
		push_error("[ScreenTransition] Scene not found: " + scene_path)
		return
	
	_is_transitioning = true
	transition_started.emit()
	
	# Block input during transition
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Fade out (to white)
	var out_duration = custom_fade_out if custom_fade_out > 0 else fade_out_duration
	await fade_out(out_duration)
	
	# Hold on white briefly
	await get_tree().create_timer(hold_duration).timeout
	
	transition_midpoint.emit()
	
	# Change scene while white
	get_tree().change_scene_to_file(scene_path)
	
	# Wait a frame for scene to load
	await get_tree().process_frame
	
	# Fade in (from white)
	var in_duration = custom_fade_in if custom_fade_in > 0 else fade_in_duration
	await fade_in(in_duration)
	
	# Restore input
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	_is_transitioning = false
	transition_completed.emit()


# Fade the screen to white (or transition color)
func fade_out(duration: float = -1.0) -> void:
	if duration < 0:
		duration = fade_out_duration
	
	overlay.modulate.a = 0.0
	
	var tween = create_tween()
	tween.tween_property(overlay, "modulate:a", 1.0, duration).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	
	await tween.finished


# Fade the screen from white (or transition color) back to transparent
func fade_in(duration: float = -1.0) -> void:
	if duration < 0:
		duration = fade_in_duration
	
	overlay.modulate.a = 1.0
	
	var tween = create_tween()
	tween.tween_property(overlay, "modulate:a", 0.0, duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	
	await tween.finished


# Quick flash effect (white flash then fade)
func flash(flash_duration: float = 0.1, fade_duration: float = 0.3) -> void:
	overlay.modulate.a = 1.0
	
	await get_tree().create_timer(flash_duration).timeout
	
	var tween = create_tween()
	tween.tween_property(overlay, "modulate:a", 0.0, fade_duration).set_ease(Tween.EASE_OUT)
	
	await tween.finished


# Set the transition color (default is white)
func set_transition_color(color: Color) -> void:
	transition_color = color
	overlay.color = transition_color


# Check if currently transitioning
func is_transitioning() -> bool:
	return _is_transitioning