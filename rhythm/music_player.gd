class_name MusicPlayer extends AudioStreamPlayer
## Handles audio playback and timing synchronization for rhythm gameplay.
## Provides frame-accurate timing data to FrameState for input judgment and chart processing.
## Author: Tyler Schauermann
## Date of last update: 04/02/2026
## Designed to support flexible timing offsets and interchangeable track sources
## for reuse across different rhythm gameplay systems.

# ========================================
# RUNTIME STATE VARIABLES
# ========================================

# Currently active music track
var current_track: Track

# Stores previous frame timestamp for delta calculation
var _previous_t: float

# Global timing offset applied to playback
var offset: float = 0

# ========================================
# FRAME STATE SYNCHRONIZATION
# ========================================

# Loads and plays a new track
func play_track(track_to_pay: Track) -> void:
	current_track = track_to_pay
	stream = current_track.load_stream()
	play()


# Updates frame timing data for rhythm processing
func fill_frame_state(frame_delta: float, frame_state: FrameState) -> void:
	if current_track == null or not playing:
		frame_state.playing_song = false
		frame_state.t = offset
		frame_state.delta = 0
		_previous_t = -1.
		return
		
	
	else:
		frame_state.playing_song = true
		frame_state.t = get_playback_position() + AudioServer.get_time_since_last_mix() + offset
		if _previous_t != -1.:
			frame_state.delta = frame_state.t - _previous_t
		else:
			frame_state.delta = frame_state.t
		
		_previous_t = frame_state.t
		
		current_track.fill_frame_state(frame_state)
	
	frame_state.previous_t = frame_state.t - frame_state.delta

# ========================================
# SIGNAL HANDLERS
# ========================================

# Resets state when audio finishes
func _on_finished() -> void:
	_previous_t = 0.
	current_track = null


# Starts playback when referee triggers chart
func _on_referee_play_chart_now(chart: Chart) -> void:
	_previous_t = 0.
	play_track(chart.track)


# Updates global audio offset from UI slider
func _on_offset_slider_change_audio_offset(offset_: float) -> void:
	offset = offset_

func stop_track() -> void:
	stop()
	current_track = null
	_previous_t = 0.0
