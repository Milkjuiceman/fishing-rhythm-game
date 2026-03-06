extends Node
## Overworld Music Manager
## Handles ambient music playback with looping, track switching, and fading
## Node Name: OverworldMusic

# Currently playing track name
var current_track: String = ""
var is_fading: bool = false
var _started: bool = false  # Track if music has been started yet

# Audio players - use two for crossfading
@onready var player_a: AudioStreamPlayer = $PlayerA
@onready var player_b: AudioStreamPlayer = $PlayerB
var active_player: AudioStreamPlayer = null

# Track library - add your tracks here
# Key: track name, Value: path to audio file
var tracks: Dictionary = {
	"main": "res://assets/audio/music/overworld_ambient.ogg",
	# TODO: Add more tracks as needed:
	# "forest": "res://assets/audio/music/forest_ambient.ogg",
	# "town": "res://assets/audio/music/town_theme.ogg",
}

# Settings
const FADE_DURATION: float = 1.5
const DEFAULT_VOLUME_DB: float = -6.0
const BUS_NAME: String = "Overworld Music"


func _ready() -> void:
	# Configure both players
	for player in [player_a, player_b]:
		player.bus = BUS_NAME
		player.volume_db = DEFAULT_VOLUME_DB
		player.finished.connect(_on_track_finished.bind(player))
	
	active_player = player_a

func play_track(track_name: String, crossfade: bool = true) -> void:
	if track_name == current_track and active_player and active_player.playing:
		return  # Already playing this track
	
	if not tracks.has(track_name):
		push_warning("[OverworldMusic] Track not found: " + track_name)
		return
	
	var track_path: String = tracks[track_name]
	if not ResourceLoader.exists(track_path):
		push_warning("[OverworldMusic] Audio file not found: " + track_path)
		return
	
	var stream = load(track_path)
	if stream == null:
		push_warning("[OverworldMusic] Failed to load audio: " + track_path)
		return
	
	current_track = track_name
	_started = true
	
	if crossfade and active_player and active_player.playing:
		_crossfade_to(stream)
	else:
		_play_immediate(stream)


func _play_immediate(stream: AudioStream) -> void:
	if active_player.playing:
		active_player.stop()
	
	active_player.stream = stream
	active_player.volume_db = DEFAULT_VOLUME_DB
	active_player.play()


func _crossfade_to(new_stream: AudioStream) -> void:
	if is_fading:
		return
	
	is_fading = true
	
	# Determine which player to fade to
	var old_player = active_player
	var new_player = player_b if active_player == player_a else player_a
	
	# Setup new player
	new_player.stream = new_stream
	new_player.volume_db = -80.0  # Start silent
	new_player.play()
	
	# Crossfade using tweens
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(old_player, "volume_db", -80.0, FADE_DURATION)
	tween.tween_property(new_player, "volume_db", DEFAULT_VOLUME_DB, FADE_DURATION)
	
	await tween.finished
	
	old_player.stop()
	active_player = new_player
	is_fading = false


func fade_out(duration: float = FADE_DURATION) -> void:
	if not active_player or not active_player.playing:
		return
	
	if is_fading:
		return
	
	is_fading = true
	
	var tween = create_tween()
	tween.tween_property(active_player, "volume_db", -80.0, duration)
	
	await tween.finished
	
	active_player.stop()
	is_fading = false


func fade_in(duration: float = FADE_DURATION) -> void:
	if not active_player or not active_player.stream:
		return
	
	if is_fading:
		return
	
	is_fading = true
	
	active_player.volume_db = -80.0
	if not active_player.playing:
		active_player.play()
	
	var tween = create_tween()
	tween.tween_property(active_player, "volume_db", DEFAULT_VOLUME_DB, duration)
	
	await tween.finished
	
	is_fading = false


func stop() -> void:
	if active_player:
		active_player.stop()
	current_track = ""
	_started = false


func pause() -> void:
	if active_player:
		active_player.stream_paused = true


func resume() -> void:
	if active_player:
		active_player.stream_paused = false


func is_playing() -> bool:
	return active_player and active_player.playing and not active_player.stream_paused


func get_current_track() -> String:
	return current_track


func _on_track_finished(player: AudioStreamPlayer) -> void:
	# Loop the track by restarting it
	if player == active_player and not is_fading:
		player.play()


# =============================================================================
# PUBLIC API - For other systems to control music
# =============================================================================

# Start overworld music with a fade-in (call when entering overworld from title)
func start_overworld_music(track_name: String = "main") -> void:
	if _started and is_playing():
		return  # Already playing
	
	_started = true
	
	if not tracks.has(track_name):
		push_warning("[OverworldMusic] Track not found: " + track_name)
		return
	
	var track_path: String = tracks[track_name]
	if not ResourceLoader.exists(track_path):
		push_warning("[OverworldMusic] Audio file not found: " + track_path)
		return
	
	var stream = load(track_path)
	if stream == null:
		push_warning("[OverworldMusic] Failed to load audio: " + track_path)
		return
	
	current_track = track_name
	
	# Start silent and fade in
	active_player.stream = stream
	active_player.volume_db = -80.0
	active_player.play()
	
	is_fading = true
	var tween = create_tween()
	tween.tween_property(active_player, "volume_db", DEFAULT_VOLUME_DB, FADE_DURATION)
	
	await tween.finished
	is_fading = false


# Call this when entering a rhythm level
func on_enter_rhythm_level() -> void:
	fade_out()


# Call this when exiting a rhythm level back to overworld
func on_exit_rhythm_level() -> void:
	if current_track != "" and _started:
		fade_in()
	else:
		start_overworld_music("main")


# Switch to a different overworld area's music
func switch_area(area_name: String) -> void:
	if tracks.has(area_name):
		play_track(area_name)
	else:
		push_warning("[OverworldMusic] No track for area: " + area_name)