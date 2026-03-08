class_name PlaceNotes extends MeshInstance3D

var lane:= 0
@export var index := 0

func _ready() -> void:
	lane = (position.x / 2) + 1.5
	
func _on_note_judged(note_index: int, frame_state: FrameState) -> void:
	var beat := fmod(frame_state.beat_offset + lane / 4.0, 1.0)
	position.y = beat / 2.0
	
	#if note_index == index:
		#scale.x -= 2
