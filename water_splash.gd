extends Area3D

signal encounter_triggered

@export var splash_lifetime: float = 10.0
@export var splash_height: float = 2.0
@export var player_group: String = "player"

@onready var particles: GPUParticles3D = $GPUParticles3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var lifetime_timer: Timer = $LifetimeTimer

func _ready():
	monitoring = true
	monitorable = true
	body_entered.connect(_on_body_entered)
	lifetime_timer.timeout.connect(_on_lifetime_timeout)

	lifetime_timer.one_shot = true
	lifetime_timer.wait_time = splash_lifetime
	lifetime_timer.start()

	particles.emitting = true

func _on_body_entered(body: Node3D):
	if body.is_in_group(player_group) or body.name == "Player":
		trigger_encounter()

func trigger_encounter():
	# Prevent multiple triggers
	if not monitoring:
		return
	monitoring = false

	encounter_triggered.emit()

	# Stop collisions and fade out
	collision_shape.disabled = true
	particles.emitting = false

	# Wait roughly one particle lifetime, then free
	await get_tree().create_timer(max(particles.lifetime, 0.1)).timeout
	queue_free()

func _on_lifetime_timeout():
	particles.emitting = false
	await get_tree().create_timer(max(particles.lifetime, 0.1)).timeout
	queue_free()
