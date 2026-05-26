extends Node
class_name Tutorial

@onready var instructions_label = $InstructionsLabel

var current_step: int = 0
var phase: int = 0
var waiting_for_input: bool = false
var flag: bool = true

signal tutorial_step_completed(step_id: int)

func _ready():
	# Register in Tutorial group so RhythmPauseMenu can check if we're waiting
	add_to_group("Tutorial")

	var rhythm_level = get_parent()
	var judge = rhythm_level.get_node("Judge")
	var progress = rhythm_level.get_node("HUD/ProgressBar")
	judge.action_required.connect(on_action_required)
	rhythm_level.action_required.connect(on_action_required)
	progress.action_required.connect(on_action_required)
	pass

## Returns true while the tutorial is waiting for player input.
## Used by RhythmPauseMenu to avoid stealing the Enter key.
func is_waiting() -> bool:
	return waiting_for_input

# Called by rhythm nodes via signal
func on_action_required(step_id: int):
	print("step #: ", step_id)
	if step_id != current_step:
		return  # ignore out-of-order signals
	
	_pause_and_show_instruction(step_id)

func _pause_and_show_instruction(step_id: int):
	get_tree().paused = true
	waiting_for_input = true
	
	match step_id:
		0:
			instructions_label.text = "This is the rhythm Levels, play them to catch fish\nPress Enter to continue"
		1:
			instructions_label.text = "Press the 'k' key to hit the\nblue note"
		2:
			instructions_label.text = "Press the 'j' key to hit the\ngreen note"
		3:
			instructions_label.text = "Press the 'f' key to hit the\nyellow note"
		4:
			instructions_label.text = "Press the 'd' key to hit the\nred note"
		5:
			instructions_label.text = "Keep hitting those notes to\nthe beat of the music"
		6:
			flag = false
			instructions_label.text = "Your progress bar is at 100% you\nhave the chance to catch this fish\nPress enter when the music starts again to reel in the fish\nor after 5 seconds of music the chance to reel in disapears"
		_:
			instructions_label.text = "Good Luck"

# Listen for player input while paused
func _input(event):
	if not waiting_for_input:
		return
	
	if current_step == 0 && Input.is_action_just_pressed(&"interact"):
		_continue_tutorial()
	elif current_step == 1 && Input.is_action_just_pressed(&"k note"):
		_continue_tutorial()
	elif current_step == 2 && Input.is_action_just_pressed(&"j note"):
		_continue_tutorial()
	elif current_step == 3 && Input.is_action_just_pressed(&"f note"):
		_continue_tutorial()
	elif current_step == 4 && Input.is_action_just_pressed(&"d note"):
		_continue_tutorial()
	elif current_step == 5 && Input.is_action_just_pressed(&"k note"):
		_continue_tutorial()
	elif current_step == 6 && Input.is_action_just_pressed(&"interact"):
		if phase == 0:
			instructions_label.text = "If the reel in disapears the misses will double,\nbut your score increases by 1000"
			phase = 1
		elif phase == 1:
			instructions_label.text = "Don't worry you'll have multiple chances to catch the fish\njust get that progress bar to 100% or finish the level\nGood Luck"
			phase = 2
		elif phase == 2:
			phase = 0
			_continue_tutorial()

func _continue_tutorial():
	waiting_for_input = false
	current_step += 1
	instructions_label.text = ""
	get_tree().paused = false
	
	emit_signal("tutorial_step_completed", current_step)
