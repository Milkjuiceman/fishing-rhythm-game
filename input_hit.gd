class_name InputHit extends Node


func fill_frame_state(frame_state: FrameState) -> void:
	frame_state.center_key_press = Input.is_action_just_pressed(&"hit center note")
	frame_state.right_key_press = Input.is_action_just_pressed(&"hit right note")
	frame_state.left_key_press = Input.is_action_just_pressed(&"hit left note")
