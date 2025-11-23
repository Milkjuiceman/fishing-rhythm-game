extends Area3D

# How long the notification is shown for
const NOTIFICATION_DURATION: float = 3.0

@export var fish_notification: Control

@export_range(-100.0, 100.0) var lake_min_x: float = 0.0
@export_range(-100.0, 100.0) var lake_max_x: float = 150.0
@export_range(-100.0, 100.0) var lake_min_z: float = 0.0
@export_range(-100.0, 100.0) var lake_max_z: float = 150.0
@export var water_height: float = 0.0

@export_range(0.1, 10.0) var respawn_delay: float = 2.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	
	if fish_notification:
		fish_notification.visible = false

# Called when the rigid body enters the area
func _on_body_entered(body: Node3D) -> void:
	if body.name == "Boat":
		_show_fish_notification()
		_respawn_at_random_location()

# Shows the fish notification and thn hides it again after a short duration
func _show_fish_notification() -> void:
	if not fish_notification:
		return
	
	fish_notification.visible = true
	fish_notification.modulate = Color(1.0, 1.0, 1.0, 1.0)
	
	await get_tree().create_timer(NOTIFICATION_DURATION).timeout
	
	fish_notification.visible = false

# Spawns water at a random location within specified cordinates
func _respawn_at_random_location() -> void:
	visible = false
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	
	await get_tree().create_timer(respawn_delay).timeout
	
	var random_x: float = randf_range(lake_min_x, lake_max_x)
	var random_z: float = randf_range(lake_min_z, lake_max_z)
	
	global_position = Vector3(random_x, water_height, random_z)
	
	visible = true
	set_deferred("monitoring", true)
	set_deferred("monitorable", true)
