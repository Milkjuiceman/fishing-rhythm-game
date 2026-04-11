extends Camera3D
## Updates camera position based on rhythm timing to follow note progression.
## Tied to Referee frame updates to maintain synchronization with gameplay.
## Author: Tyler Schauermann
## Date of last update: 04/02/2026
## Designed for simple camera tracking, can be extended for dynamic effects
## such as zoom, shake, or cinematic transitions.

# ========================================
# CAMERA UPDATE
# ========================================

# Updates camera position based on rhythm timing
func _on_referee_process(frame_state: FrameState) -> void:
	position.z = frame_state.t * frame_state.note_speed - 2;
