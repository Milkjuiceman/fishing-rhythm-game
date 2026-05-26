extends ProgressBar

@export var referee: TutorialReferee

func _ready() -> void:
	set_process(false)


func _on_referee_timer_activated() -> void:
	set_process(true)


func _process(_delta: float) -> void:
	value = referee.timer.time_left


func _on_referee_timer_done() -> void:
	set_process(false)
