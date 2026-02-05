extends Node

# Some array holds the locations of all the "notes" for the player to "hit". There is a variable
# that holds the current location of the detection zone (might be camera position). Wait for player
# input, once the player has pressed the input check the distance from the desired postion of the 
# current note. If the note is way out of the detection area then ignore input, otherwise log the
# difference between when the player pressed the input and where the correct postion is. Finally 
# after the player has successfully inputed the notes 10 times calculate the average offset of the
# input and display that value.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
