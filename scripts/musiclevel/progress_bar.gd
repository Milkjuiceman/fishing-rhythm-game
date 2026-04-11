extends ProgressBar
class_name CatchProgressBar
## Rhythm fishing minigame progress bar
## Tracks hits/misses and signals catch availability or failure
## Author: Tyler Schauermann
## Date of last update: 04/02/2026
## Designed for dynamic updating and integration with Referee system

# ========================================
# STATE VARIABLES
# ========================================

# Updates if the player can reel in or not
var catchable: bool = false

# Track previous hit count
var prev_hit = 0

 # Track previous miss count
var prev_miss = 0

# Track number of reel_ins have been denied
var reel_ins = 1

# ========================================
# SIGNALS
# ========================================

signal catch_failed
signal catch_available
signal catch_unavailable

# ========================================
# PROCESSING FRAME STATE
# ========================================

func _on_referee_process(frame_state: FrameState) -> void:
	if frame_state.scorecard == null:
		return
	_update_from_scorecard(frame_state.scorecard)
	#print(value)


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

# ========================================
# RESET AND REEL HANDLING
# ========================================

func reset():
	prev_hit = 0
	prev_miss = 0
	catchable = false


func _on_referee_reel_in_denied() -> void:
	value = 50.0
	reel_ins += reel_ins
