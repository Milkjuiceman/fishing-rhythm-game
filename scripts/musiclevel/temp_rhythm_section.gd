extends Node3D

@export var referee: Referee;


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	referee.play_chart_now.emit(referee.chart);
	referee.judge.song_finished.connect(_on_song_finished)
	
func _on_song_finished(scorecard: Scorecard) -> void:
	_reward_player(scorecard)

func _reward_player(scorecard: Scorecard) -> void:
	var accuracy := scorecard.get_hit_accuracy()
	var combo := scorecard.combo
	
	
	
	
	
