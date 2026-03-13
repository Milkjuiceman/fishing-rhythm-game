class_name PlaceNotes extends MeshInstance3D

var lane:= 0.0
@export var index := 0

func _ready() -> void:
	lane = (position.x / 2) + 1.5
	
func _on_note_judged(note_index: int, frame_state: FrameState, status: String) -> void:
	var beat := fmod(frame_state.beat_offset + lane / 4.0, 1.0)
	position.y = beat / 2.0
	
	if note_index == index && status == "hit":
		#var music_note = get_child(0)

		var tween = create_tween().set_ease(Tween.EASE_OUT)

		# bubble pop
		tween.tween_property(self, "scale", Vector3(2.0, 2.0, 2.0), 0.04)
		tween.tween_property(self, "scale", Vector3(0.8, 0.8, 0.8), 0.08)

		# music note floats upward at the same time
		#tween.parallel().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		#tween.parallel().tween_property(music_note, "position:y", 5.0, 0.5)

		tween.tween_callback(queue_free)
