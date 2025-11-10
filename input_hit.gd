class_name InputHit extends Node


func fill_frame_state(frame_state: FrameState) -> void:
	frame_state.key_press = Input.is_action_just_pressed(&"hit note")
