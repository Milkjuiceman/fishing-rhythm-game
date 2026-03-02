extends Node
class_name BoatSFX
## Boat Sound Effects Controller
## Attach as child of any boat to add engine, idle, and impact sounds
##
## Setup:
## 1. Add a Node child to your boat
## 2. Attach this script to it
## 3. Sound files are auto-loaded from res://assets/audio/sfx/boat/

# Audio file paths
const ENGINE_START_PATH: String = "res://assets/audio/sfx/engine_start.ogg"
const ENGINE_LOOP_PATH: String = "res://assets/audio/sfx/engine_loop.ogg"
const ENGINE_STOP_PATH: String = "res://assets/audio/sfx/engine_stop.ogg"
const IDLE_LOOP_PATH: String = "res://assets/audio/sfx/idle_loop.ogg"
const IMPACT_PATHS: Array[String] = [
	"res://assets/audio/sfx/impact_01.ogg",
	"res://assets/audio/sfx/impact_02.ogg",
	"res://assets/audio/sfx/impact_03.ogg",
]

@export_group("Volume Settings")
@export_range(-40.0, 10.0) var engine_volume_db: float = -6.0
@export_range(-40.0, 10.0) var idle_volume_db: float = -10.0
@export_range(-40.0, 10.0) var impact_volume_db: float = 0.0

@export_group("Behavior")
@export var speed_threshold_for_engine: float = 1.0  # Min speed to switch from idle to engine
@export var engine_pitch_min: float = 0.85
@export var engine_pitch_max: float = 1.3
@export var impact_cooldown: float = 0.3  # Prevent impact sound spam

# Audio players
var _engine_player: AudioStreamPlayer3D
var _idle_player: AudioStreamPlayer3D
var _oneshot_player: AudioStreamPlayer3D  # For start, stop, impact sounds

# Preloaded streams
var _engine_loop_stream: AudioStream
var _idle_loop_stream: AudioStream
var _engine_start_stream: AudioStream
var _engine_stop_stream: AudioStream
var _impact_streams: Array[AudioStream] = []

# State tracking
var _boat: Node3D = null
var _is_moving: bool = false
var _current_speed: float = 0.0
var _impact_timer: float = 0.0
var _engine_started: bool = false

# Constants
const BUS_NAME: String = "SFX"
const CROSSFADE_DURATION: float = 0.4


func _ready() -> void:
	# Find parent boat
	_boat = _find_boat_parent()
	if not _boat:
		push_warning("[BoatSFX] No boat parent found! Attach this to a Boat node.")
		return
	
	# Load audio streams
	_load_audio_streams()
	
	# Create audio players
	_setup_audio_players()
	
	# Start with idle sound after a brief delay
	call_deferred("_initialize_audio")


func _find_boat_parent() -> Node3D:
	var parent = get_parent()
	while parent:
		if parent is Boat or parent.is_in_group("boat") or "velocity" in parent or "linear_velocity" in parent:
			return parent
		parent = parent.get_parent()
	
	# Fallback: just use direct parent if it's Node3D
	if get_parent() is Node3D:
		return get_parent()
	
	return null


func _load_audio_streams() -> void:
	# Load engine sounds
	if ResourceLoader.exists(ENGINE_LOOP_PATH):
		_engine_loop_stream = load(ENGINE_LOOP_PATH)
	if ResourceLoader.exists(IDLE_LOOP_PATH):
		_idle_loop_stream = load(IDLE_LOOP_PATH)
	if ResourceLoader.exists(ENGINE_START_PATH):
		_engine_start_stream = load(ENGINE_START_PATH)
	if ResourceLoader.exists(ENGINE_STOP_PATH):
		_engine_stop_stream = load(ENGINE_STOP_PATH)
	
	# Load impact sounds
	for path in IMPACT_PATHS:
		if ResourceLoader.exists(path):
			var stream = load(path)
			if stream:
				_impact_streams.append(stream)


func _setup_audio_players() -> void:
	# Engine loop player
	_engine_player = AudioStreamPlayer3D.new()
	_engine_player.bus = BUS_NAME
	_engine_player.volume_db = -80.0  # Start silent
	_engine_player.max_distance = 50.0
	_engine_player.name = "EnginePlayer"
	if _engine_loop_stream:
		_engine_player.stream = _engine_loop_stream
	add_child(_engine_player)
	
	# Idle loop player
	_idle_player = AudioStreamPlayer3D.new()
	_idle_player.bus = BUS_NAME
	_idle_player.volume_db = -80.0  # Start silent
	_idle_player.max_distance = 40.0
	_idle_player.name = "IdlePlayer"
	if _idle_loop_stream:
		_idle_player.stream = _idle_loop_stream
	add_child(_idle_player)
	
	# One-shot player for start/stop/impact
	_oneshot_player = AudioStreamPlayer3D.new()
	_oneshot_player.bus = BUS_NAME
	_oneshot_player.volume_db = 0.0
	_oneshot_player.max_distance = 60.0
	_oneshot_player.name = "OneshotPlayer"
	add_child(_oneshot_player)


func _initialize_audio() -> void:
	# Play engine start sound with fade in
	if _engine_start_stream:
		_play_oneshot_with_fade(_engine_start_stream, engine_volume_db, 0.15)
	
	# Start idle loop
	if _idle_player.stream:
		_idle_player.play()
		var tween = create_tween()
		tween.tween_property(_idle_player, "volume_db", idle_volume_db, CROSSFADE_DURATION)
	
	_engine_started = true


func _process(delta: float) -> void:
	if not _boat or not _engine_started:
		return
	
	# Update impact cooldown
	if _impact_timer > 0:
		_impact_timer -= delta
	
	# Get current speed
	_current_speed = _get_boat_speed()
	
	# Determine if moving
	var was_moving = _is_moving
	_is_moving = _current_speed > speed_threshold_for_engine
	
	# Handle state transitions
	if _is_moving and not was_moving:
		_switch_to_engine()
	elif not _is_moving and was_moving:
		_switch_to_idle()
	
	# Update engine pitch based on speed
	if _is_moving:
		_update_engine_pitch()
	
	# Update player positions
	_update_player_positions()


func _get_boat_speed() -> float:
	if "velocity" in _boat:
		return _boat.velocity.length()
	elif "linear_velocity" in _boat:
		return _boat.linear_velocity.length()
	elif "current_speed" in _boat:
		return abs(_boat.current_speed)
	return 0.0


func _switch_to_engine() -> void:
	# Start engine loop if not playing
	if _engine_player.stream and not _engine_player.playing:
		_engine_player.play()
	
	# Crossfade: idle down, engine up
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(_idle_player, "volume_db", -80.0, CROSSFADE_DURATION)
	tween.tween_property(_engine_player, "volume_db", engine_volume_db, CROSSFADE_DURATION)


func _switch_to_idle() -> void:
	# Start idle loop if not playing
	if _idle_player.stream and not _idle_player.playing:
		_idle_player.play()
	
	# Crossfade: engine down, idle up
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(_engine_player, "volume_db", -80.0, CROSSFADE_DURATION)
	tween.tween_property(_idle_player, "volume_db", idle_volume_db, CROSSFADE_DURATION)


func _update_engine_pitch() -> void:
	if not _engine_player.playing:
		return
	
	# Map speed to pitch
	var max_speed = 15.0
	var speed_ratio = clamp(_current_speed / max_speed, 0.0, 1.0)
	var target_pitch = lerp(engine_pitch_min, engine_pitch_max, speed_ratio)
	
	# Smooth pitch changes
	_engine_player.pitch_scale = lerp(_engine_player.pitch_scale, target_pitch, 0.1)


func _update_player_positions() -> void:
	var boat_pos = _boat.global_position
	_engine_player.global_position = boat_pos
	_idle_player.global_position = boat_pos
	_oneshot_player.global_position = boat_pos


func _play_oneshot(stream: AudioStream, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	_oneshot_player.stream = stream
	_oneshot_player.volume_db = volume_db
	_oneshot_player.pitch_scale = pitch
	_oneshot_player.play()


func _play_oneshot_with_fade(stream: AudioStream, target_volume_db: float = 0.0, fade_duration: float = 0.15) -> void:
	_oneshot_player.stream = stream
	_oneshot_player.volume_db = -40.0  # Start quiet
	_oneshot_player.pitch_scale = 1.0
	_oneshot_player.play()
	
	# Fade in
	var tween = create_tween()
	tween.tween_property(_oneshot_player, "volume_db", target_volume_db, fade_duration)


func _play_oneshot_with_fade_out(stream: AudioStream, target_volume_db: float = 0.0, fade_duration: float = 0.2) -> void:
	_oneshot_player.stream = stream
	_oneshot_player.volume_db = target_volume_db
	_oneshot_player.pitch_scale = 1.0
	_oneshot_player.play()
	
	# Calculate when to start fading (stream length minus fade duration)
	var stream_length = stream.get_length()
	var fade_start_time = max(0.0, stream_length - fade_duration)
	
	# Wait then fade out
	await get_tree().create_timer(fade_start_time).timeout
	if _oneshot_player.playing:
		var tween = create_tween()
		tween.tween_property(_oneshot_player, "volume_db", -40.0, fade_duration)


# =============================================================================
# PUBLIC API
# =============================================================================

## Play impact sound (call when boat collides with something)
func play_impact(intensity: float = 1.0) -> void:
	# Respect cooldown
	if _impact_timer > 0:
		return
	_impact_timer = impact_cooldown
	
	# Pick random impact sound
	if _impact_streams.is_empty():
		return
	
	var stream = _impact_streams.pick_random()
	var volume = impact_volume_db + lerp(-6.0, 3.0, clamp(intensity, 0.0, 1.0))
	var pitch = randf_range(0.9, 1.1)
	
	_play_oneshot(stream, volume, pitch)


## Stop all boat sounds (call when docking, entering shop, etc.)
func stop_engine() -> void:
	if not _engine_started:
		return
	
	_engine_started = false
	
	# Play stop sound with fade out at the end
	if _engine_stop_stream:
		_play_oneshot_with_fade_out(_engine_stop_stream, engine_volume_db, 0.2)
	
	# Fade out loops
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(_engine_player, "volume_db", -80.0, CROSSFADE_DURATION)
	tween.tween_property(_idle_player, "volume_db", -80.0, CROSSFADE_DURATION)
	
	await tween.finished
	_engine_player.stop()
	_idle_player.stop()


## Start boat sounds (call when leaving dock, exiting shop, etc.)
func start_engine() -> void:
	if _engine_started:
		return
	
	_initialize_audio()


## Check if engine sounds are active
func is_engine_running() -> bool:
	return _engine_started
