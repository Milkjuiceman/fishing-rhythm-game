extends ProgressBar
class_name CatchProgressBar
## Rhythm fishing minigame progress bar
## Tracks hits/misses and signals catch availability or failure
## Author: Tyler Schauermann
## Date of last update: 04/22/2026

# ========================================
# STATE VARIABLES
# ========================================

var catchable: bool = false
var prev_hit: int = 0
var prev_miss: int = 0
var reel_ins: int = 1

## Prevents catch_failed from firing more than once per level.
var _failed: bool = false

## Only allows the fail check once the song is actually playing.
## Prevents instant failure on the first frame when the bar starts at 0.
var _song_started: bool = false

# ========================================
# SIGNALS
# ========================================

signal catch_failed
signal catch_available
signal catch_unavailable

# ========================================
# FRAME UPDATE
# ========================================

func _on_referee_process(frame_state: FrameState) -> void:
	if frame_state.scorecard == null:
		return

	# Mark song as started once audio is actually playing
	if frame_state.playing_song and not _song_started:
		_song_started = true

	_update_from_scorecard(frame_state.scorecard)

func _update_from_scorecard(scorecard: Scorecard) -> void:
	if _failed:
		return  # Already failed — stop all processing

	# Process hits
	var hits_delta = scorecard.hits - prev_hit
	value += hits_delta

	# Process misses
	var misses_delta = scorecard.misses - prev_miss
	if misses_delta > 0:
		value -= misses_delta * reel_ins

	value = clamp(value, min_value, max_value)

	prev_hit = scorecard.hits
	prev_miss = scorecard.misses

	# Only check for failure once the song has begun —
	# prevents instant fail on the first frame when bar starts at 0
	if _song_started and value <= min_value and not catchable:
		print("[ProgressBar] depleted, level failed")
		_failed = true
		emit_signal("catch_failed")
		return

	# Bar filled — catch window opens
	if value >= max_value and not catchable:
		catchable = true
		print("[ProgressBar] filled, fish catchable")
		emit_signal("catch_available")

	# Bar dropped below threshold — catch window closes
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
	_failed = false
	_song_started = false

func _on_referee_reel_in_denied() -> void:
	value = 50.0
	reel_ins += reel_ins		
