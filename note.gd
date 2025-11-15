class_name PlaceNotes extends MeshInstance3D 


func _on_referee_process(frame_state: FrameState) -> void:
	scale.x = frame_state.beat_offset * .5 + 1;
	scale.y = frame_state.beat_offset * .5 + 1;
	scale.z = frame_state.beat_offset * .5 + 1;
	
#	lerp(bottom, ceiling, ocolation)
