extends CanvasLayer
class_name RhythmCountdown
## Rhythm Countdown Screen
## Displays a 3-2-1-GO countdown before the rhythm minigame starts

signal countdown_finished

@onready var background: ColorRect = $Background
@onready var count_label: Label = $CountLabel
@onready var subtitle_label: Label = $SubtitleLabel

# Countdown settings
@export var countdown_start: int = 3
@export var count_duration: float = 1.0  # Time per count
@export var go_duration: float = 0.8     # Time "GO!" stays on screen
@export var initial_delay: float = 0.3   # Delay before countdown starts
@export var start_from_white: bool = true  # Whether to fade from white to dark

# Animation settings
const PULSE_SCALE: float = 1.3
const FINAL_SCALE: float = 0.8

# Colors
const DARK_BG_COLOR: Color = Color(0.02, 0.02, 0.06, 0.95)
const WHITE_COLOR: Color = Color(1.0, 1.0, 1.0, 1.0)

var _current_count: int = 0


func _ready() -> void:
	# Start hidden, call start_countdown() to begin
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS


func start_countdown() -> void:
	visible = true
	_current_count = countdown_start
	
	# Pause the game during countdown
	get_tree().paused = true
	
	# Set initial state based on whether we're coming from white transition
	if start_from_white:
		background.color = WHITE_COLOR
		background.modulate.a = 1.0
	else:
		background.color = DARK_BG_COLOR
		background.modulate.a = 0.0
	
	subtitle_label.text = "Get Ready!"
	subtitle_label.modulate.a = 0.0
	count_label.modulate.a = 0.0
	
	if start_from_white:
		# Transition from white to dark background
		var color_tween = create_tween()
		color_tween.tween_property(background, "color", DARK_BG_COLOR, 0.5).set_ease(Tween.EASE_OUT)
		await color_tween.finished
	else:
		# Fade in dark background
		var fade_in = create_tween()
		fade_in.tween_property(background, "modulate:a", 1.0, 0.4)
		await fade_in.finished
	
	# Fade in subtitle
	var sub_fade = create_tween()
	sub_fade.tween_property(subtitle_label, "modulate:a", 1.0, 0.3)
	await sub_fade.finished
	
	# Initial delay to let player prepare
	await get_tree().create_timer(initial_delay).timeout
	
	# Start the count sequence
	await _do_countdown()


func _do_countdown() -> void:
	while _current_count > 0:
		await _show_count(str(_current_count))
		_current_count -= 1
	
	# Show "GO!"
	await _show_go()
	
	# Fade out and finish
	await _fade_out()
	
	# Resume game and emit signal
	get_tree().paused = false
	countdown_finished.emit()
	
	# Remove self after countdown
	queue_free()


func _show_count(text: String) -> void:
	count_label.text = text
	count_label.scale = Vector2.ONE * PULSE_SCALE
	count_label.modulate.a = 0.0
	
	# Color based on count
	match int(text):
		3:
			count_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))  # Red
		2:
			count_label.add_theme_color_override("font_color", Color(1.0, 0.7, 0.2))  # Orange
		1:
			count_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4))  # Green
	
	# Animate: scale down + fade in
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(count_label, "scale", Vector2.ONE, count_duration * 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(count_label, "modulate:a", 1.0, count_duration * 0.25)
	
	await tween.finished
	
	# Hold for a moment
	await get_tree().create_timer(count_duration * 0.25).timeout
	
	# Fade out
	var fade_tween = create_tween()
	fade_tween.set_parallel(true)
	fade_tween.tween_property(count_label, "modulate:a", 0.0, count_duration * 0.25)
	fade_tween.tween_property(count_label, "scale", Vector2.ONE * FINAL_SCALE, count_duration * 0.25)
	
	await fade_tween.finished


func _show_go() -> void:
	count_label.text = "GO!"
	count_label.add_theme_color_override("font_color", Color(0.2, 0.9, 1.0))  # Cyan
	count_label.scale = Vector2.ONE * 0.5
	count_label.modulate.a = 0.0
	
	# Hide subtitle
	var sub_tween = create_tween()
	sub_tween.tween_property(subtitle_label, "modulate:a", 0.0, 0.2)
	
	# Explosive scale up
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(count_label, "scale", Vector2.ONE * 1.5, go_duration * 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(count_label, "modulate:a", 1.0, go_duration * 0.2)
	
	await tween.finished
	
	# Hold longer so player can see "GO!"
	await get_tree().create_timer(go_duration * 0.5).timeout


func _fade_out() -> void:
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(background, "modulate:a", 0.0, 0.35)
	tween.tween_property(count_label, "modulate:a", 0.0, 0.35)
	tween.tween_property(count_label, "scale", Vector2.ONE * 2.0, 0.35)
	
	await tween.finished