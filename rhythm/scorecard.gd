class_name Scorecard extends RefCounted

signal rating_hit(rating: String, side: int)

enum NoteStateEnum {WAITING = 0, HIT = 1, MISS = 2}

var note_status := PackedByteArray([])
# the value inside of these should be disregarded unless note status is hit
var note_temporal_accuracy := PackedFloat32Array([])

var misses: int = 0
var hits: int = 0
var combo: int = 0
var temporal_error_displacement: float = 0.
var temporal_error_cumulative: float = 0.
var score: int = 0


func _init(chart_reference := Chart.new()):
	note_status = PackedByteArray([])
	note_temporal_accuracy = PackedFloat32Array([])
	note_status.resize(chart_reference.note_timings.size())
	note_temporal_accuracy.resize(chart_reference.note_timings.size())
	note_status.fill(NoteStateEnum.WAITING)
	note_temporal_accuracy.fill(0.)


func miss_note(index: int, column: int) -> void:
	assert(index < note_status.size(), "Cant miss a note not in the chart!")
	note_status[index] = NoteStateEnum.MISS
	penalty(column)
	
	
func penalty(i: int) -> void:
	var side = 0
	misses += 1
	combo = 0
	
	if i >= 2:
		side = 1
	else:
		side = 0
	
	emit_signal("rating_hit", "Miss", side)


func hit_note(index: int, temporal_accuracy: float) -> void:
	if index >= note_status.size():
		return;
	note_status[index] = NoteStateEnum.HIT
	note_temporal_accuracy[index] = temporal_accuracy
	hits += 1
	combo += 1
	temporal_error_displacement += temporal_accuracy
	temporal_error_cumulative += abs(temporal_accuracy)


func get_hit_accuracy() -> float:
	return hits / max(hits + misses, 1)

func get_average_temporal_offset() -> float:
	return temporal_error_displacement / max(hits, 1)

func get_average_temporal_error() -> float:
	if hits == 0:
		return 0.
	else:
		return temporal_error_cumulative / hits
		
func update_score(accuracy: float, i: int) -> void:
	var rating = ""
	var side = 0
	
	if accuracy <= 0.03:
		rating = "Perfect"
		if combo < 10:
			score += 10
		else:
			score += 40
	elif accuracy <= 0.07:
		rating = "Good"
		if combo < 10:
			score += 7
		else:
			score += 28
	else:
		rating = "Bad"
		if combo < 10:
			score += 3
		else:
			score += 12
			
	if i >= 2:
		side = 1
	else:
		side = 0

	# Emit the signal with the rating
	emit_signal("rating_hit", rating, side)
