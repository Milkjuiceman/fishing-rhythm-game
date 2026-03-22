extends Label

@export var judge: EditorJudge

func _on_referee_process(frame_state: FrameState) -> void:
	
	var compared_t: float = lerp(frame_state.t, frame_state.previous_t, 0.5)
	
	if judge.start > compared_t or judge.finish < compared_t or judge.testing:
		text = " "
	else:
		text = "editing"
