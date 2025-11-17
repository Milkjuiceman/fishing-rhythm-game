extends Camera3D


func _on_referee_process(frame_state: FrameState) -> void:
	position.z = frame_state.t * frame_state.note_speed - 2;
