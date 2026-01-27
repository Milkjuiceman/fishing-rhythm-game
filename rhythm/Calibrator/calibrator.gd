extends Node3D

@export var referee: CalibratorReferee;


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	referee.play_chart_now.emit(referee.chart);
