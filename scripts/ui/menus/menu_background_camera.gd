extends Camera3D

@export var orbit_speed: float = 0.08
@export var orbit_radius: float = 150.0
@export var orbit_height: float = 40.0
@export var orbit_center: Vector3 = Vector3(300, 0, 350)  # ← center of your lake area
@export var look_at_target: Vector3 = Vector3(300, 5, 350) # ← same spot, slightly above ground

var _angle: float = 0.0

func _ready() -> void:
	_angle = 0.0
	_update_position()

func _process(delta: float) -> void:
	_angle += orbit_speed * delta
	if _angle > TAU:
		_angle -= TAU
	_update_position()

func _update_position() -> void:
	position = orbit_center + Vector3(
		cos(_angle) * orbit_radius,
		orbit_height,
		sin(_angle) * orbit_radius
	)
	look_at(look_at_target, Vector3.UP)
