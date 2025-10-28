@icon("res://rhythm/track_icon.svg")
class_name Track
extends Resource

@export var audio_location: StringName
#@export var cover_location: StringName
@export var artists: String
@export var title: String
@export var bpm: Dictionary[float, float]


func _init(_audio_location := "", _cover_location := "", _artists := "", _title := "", _bpm: Dictionary[float, float] = {0.: 60.}):
	audio_location = _audio_location
	#cover_location = _cover_location
	artists = _artists
	title = _title
	bpm = _bpm


func _to_string() -> String:
	return title + " by " + artists


func fill_frame_state(frame_state: FrameState) -> void:
	var t = frame_state.t
	
	frame_state.beat = _get_beat(t)
	
	var lastest_bpm_key: float = 0.
	for bpm_key in bpm.keys():
		if bpm_key <= t && bpm_key > lastest_bpm_key:
			lastest_bpm_key = bpm_key
	
	frame_state.bpm = bpm[lastest_bpm_key]
	frame_state.seconds_per_beat = 60. / frame_state.bpm
	
	var t_offset = t - lastest_bpm_key
	frame_state.beat_offset = fmod(t_offset, frame_state.seconds_per_beat) / frame_state.seconds_per_beat


# todo optimize this if its gonna run every frame
func _get_beat(t: float) -> int:
	var bpm_keys = bpm.keys()
	bpm_keys.sort()
	bpm_keys.push_back(1000000000000000000)
	var beats = 0
	for i in range(len(bpm_keys)):
		var bpm_key = bpm_keys[i]
		if bpm_key < t:
			var next_bpm_key = bpm_keys[i+1]
			var length_of_bpm_section: float = min(next_bpm_key, t) - bpm_key
			var specific_bpm = bpm[bpm_key]
			var seconds_per_beat: float = 60. / specific_bpm
			var beats_from_this := length_of_bpm_section / seconds_per_beat
			beats += floori(beats_from_this)
			if t > next_bpm_key && fmod(beats_from_this, 1.) > 0.05:
				beats += 1
	return beats


func load_stream() -> AudioStream:
	return AudioStreamOggVorbis.load_from_file(audio_location)
