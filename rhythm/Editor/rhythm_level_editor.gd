extends Node3D

@export var referee: EditorReferee;


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	DisplayServer.window_move_to_foreground()
	referee.play_chart_now.emit(referee.chart)
