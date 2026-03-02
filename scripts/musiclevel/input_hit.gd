class_name InputHit extends Node


func fill_frame_state(frame_state: FrameState) -> void:
    frame_state.d_key_press = Input.is_action_just_pressed(&"d note")
    frame_state.f_key_press = Input.is_action_just_pressed(&"f note")
    frame_state.j_key_press = Input.is_action_just_pressed(&"j note")
    frame_state.k_key_press = Input.is_action_just_pressed(&"k note")
    frame_state.enter_key_press = Input.is_action_just_pressed(&"interact")