class_name PlaceNotes extends MeshInstance3D


func _on_referee_process(frame_state: FrameState) -> void:
	scale.z = frame_state.beat_offset * 10
