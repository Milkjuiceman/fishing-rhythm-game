class_name Scorecard extends RefCounted

enum NoteStateEnum {WAITING = 0, HIT = 1, MISS = 2}

var note_status := PackedByteArray([])
# the value inside of these should be disregarded unless note status is hit
var note_temporal_accuracy := PackedFloat32Array([])

var misses: int = 0
var hits: int = 0
var combo: int = 0
var temporal_error_displacement: float = 0.
var temporal_error_cumulative: float = 0.
var start_buffer: int = 5 # cant fail until x notes have passed


func _init(chart_reference := Chart.new()):
	note_status = PackedByteArray([])
	note_temporal_accuracy = PackedFloat32Array([])
	note_status.resize(chart_reference.note_timings.size())
	note_temporal_accuracy.resize(chart_reference.note_timings.size())
	note_status.fill(NoteStateEnum.WAITING)
	note_temporal_accuracy.fill(0.)


func miss_note(index: int) -> void:
	if index >= note_status.size():
		return;
	note_status[index] = NoteStateEnum.MISS
	_penalty()
	
	
func _penalty() -> void:
	if start_buffer > 0:
		combo = 0
		start_buffer -= 1
	else:
		combo = 0
		misses += 1


func hit_note(index: int, temporal_accuracy: float) -> void:
	if index >= note_status.size():
		return;
	note_status[index] = NoteStateEnum.HIT
	note_temporal_accuracy[index] = temporal_accuracy
	hits += 1
	combo += 1
	temporal_error_displacement += temporal_accuracy
	temporal_error_cumulative += abs(temporal_accuracy)
	if start_buffer > 0:
		start_buffer -= 1


func get_hit_accuracy() -> float:
	return hits / max(hits + misses, 1)

func get_average_temporal_offset() -> float:
	return temporal_error_displacement / max(hits, 1)

func get_average_temporal_error() -> float:
	return temporal_error_cumulative / max(hits, 1)
