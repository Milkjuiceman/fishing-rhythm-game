class_name InputHit extends Node
## Captures player input and maps it to FrameState for rhythm processing.
## Provides input data to the Referee and Judge systems for note interaction.
## Author: Tyler Schauermann
## Date of last update: 04/02/2026
## Designed to allow flexible input remapping and expansion to additional input types.

# ========================================
# INPUT PROCESSING
# ========================================

# Updates FrameState with current frame input presses
func fill_frame_state(frame_state: FrameState) -> void:
	frame_state.d_key_press = Input.is_action_just_pressed(&"d note")
	frame_state.f_key_press = Input.is_action_just_pressed(&"f note")
	frame_state.j_key_press = Input.is_action_just_pressed(&"j note")
	frame_state.k_key_press = Input.is_action_just_pressed(&"k note")
	frame_state.enter_key_press = Input.is_action_just_pressed(&"interact")
