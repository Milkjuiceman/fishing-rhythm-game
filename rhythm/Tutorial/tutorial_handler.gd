extends Node

@export var instructions: Instructions

var flags: Array[bool] = [false, false, false]
var index: int = 0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	flags[index] = true
	
	if flags[1] == true:
		instructions.text = "String"
		if Input.is_action_just_pressed(&"k note"):
			get_tree().paused = false
			
	++index


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
