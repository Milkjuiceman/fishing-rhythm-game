class_name CalibratorInputHit extends Node


func fill_frame_state(frame_state: FrameState) -> void:
	frame_state.space_key_press = Input.is_action_just_pressed(&"calibration")
