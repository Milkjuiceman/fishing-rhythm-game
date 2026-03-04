extends ProgressBar
class_name CatchProgressBar

## Rhythm Game Progress Bar
## Tracks player performance during fishing minigame based on hits and misses
## Boots player back to previous scene if progress reaches 0%

var catchable: bool = false
var prev_hit = 0  # Track previous hit count
var prev_miss = 0  # Track previous miss count
var reel_ins = 1

signal catch_failed
signal catch_available
signal catch_unavailable

func _on_referee_process(frame_state: FrameState) -> void:
	if frame_state.scorecard == null:
		return
	_update_from_scorecard(frame_state.scorecard)

# Update progress bar based on rhythm game performance
func _update_from_scorecard(scorecard: Scorecard) -> void:
	# process hits
	var hits_delta = scorecard.hits - prev_hit
	value += hits_delta

	# Process misses 
	var misses_delta = scorecard.misses - prev_miss
	if misses_delta > 0:
		value -= misses_delta * reel_ins
	
	value = clamp(value, min_value, max_value)
	
	# Update tracking variables
	prev_hit = scorecard.hits
	prev_miss = scorecard.misses
	
	# Check if player hit 0%
	if value <= min_value and not catchable:
		print("[ProgressBar] depleted, level failed")
		emit_signal("catch_failed")
		
	if value >= max_value and not catchable:
		catchable = true
		print("[ProgressBar] filled, fish catchable")
		emit_signal("catch_available")
		
	if value < 80 and catchable:
		catchable = false
		emit_signal("catch_unavailable")
		
func reset():
	prev_hit = 0
	prev_miss = 0
	catchable = false


func _on_referee_reel_in_denied() -> void:
	value = 50.0
	reel_ins += reel_ins
