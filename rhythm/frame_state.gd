class_name FrameState extends RefCounted

#set by Referee
var note_speed: float = 1.
var input_offset: float = 0.
var audio_offset: float = 0.

# set by MusicPlayer
var playing_song: bool = false
# if playing_song is false will be the frame delta. If was false the previous frame will be t. Otherwise will be the music's delta
var delta: float = 1. / 60.
# will be music to visual offset is playing_song is false
var t: float = 0.
# always t - delta, even when those values are invalid
var previous_t: float = 0.

# set by Track (left at default if playing_song is false)
var bpm: float = 60.
var beat_offset: float = 0.
var beat: int = 0
var seconds_per_beat: float = 1. / 60.

## set by MouseInput
#var mouse_velocity: Vector2 = Vector2(0., 0.)
#var smoothed_mouse_velocity: Vector2 = Vector2(0., 0.)

# set by Judge
# may be null
var scorecard: Scorecard = null

# set by InputHit
var key_press: bool = false
