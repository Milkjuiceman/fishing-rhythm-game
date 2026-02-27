extends Node3D
## Rhythm Level Controller
## Manages the rhythm minigame sequence including countdown and gameplay start

const COUNTDOWN_SCENE = preload("res://scenes/ui/transitions/rhythm_countdown.tscn")

@export var referee: Referee

var _countdown_instance: RhythmCountdown = null


func _ready() -> void:
	# Don't start immediately - show countdown first
	_show_countdown()


func _show_countdown() -> void:
	# Create countdown instance
	_countdown_instance = COUNTDOWN_SCENE.instantiate()
	add_child(_countdown_instance)
	
	# Connect to countdown finished signal
	_countdown_instance.countdown_finished.connect(_on_countdown_finished)
	
	# Start the countdown
	_countdown_instance.start_countdown()


func _on_countdown_finished() -> void:
	# Countdown is done, start the rhythm gameplay
	print("[RhythmLevel] Countdown finished, starting chart!")
	referee.play_chart_now.emit(referee.chart)
