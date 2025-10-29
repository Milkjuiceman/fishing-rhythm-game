@icon("res://rhythm/chart_icon.svg")
class_name Chart extends Resource

@export var track: Track

@export var note_timings := PackedFloat64Array([])
#@export var note_angles := PackedFloat32Array([])

func _init(
		track_ := Track.new(),
		note_timings_ := PackedFloat64Array([]),
		#note_angles_ := PackedFloat32Array([])
	):
	track = track_
	note_timings = note_timings_
	#note_angles = note_angles_
