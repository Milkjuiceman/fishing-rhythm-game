extends VehicleBase
class_name Boat

var mouse_movement = Vector2()
var locked_y_position = 0.0

@onready var detection_area = $DetectionArea

func _ready():
	super._ready()
	
	# Set boat-specific speeds
	forward_speed = 50
	boost_speed = 100
	turn_strength = 2.0
	
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	axis_lock_angular_x = true
	axis_lock_angular_z = true
	
	locked_y_position = global_transform.origin.y
	
	# Increase max contacts for better collision detection
	contact_monitor = true
	max_contacts_reported = 4

# Repositioning the boat to fix water height
func update_water_lock():
	locked_y_position = global_transform.origin.y

func get_detection_area() -> Area3D:
	return detection_area
		
func _unhandled_input(event):
	if event is InputEventMouseMotion:
		mouse_movement += event.relative
		
func _physics_process(_delta):
	if get_tree().paused:
		return
		
	if mouse_movement != Vector2():
		$H.rotation_degrees.y += -mouse_movement.x
		mouse_movement = Vector2()
	
	var pos = global_transform.origin
	pos.y = locked_y_position
	global_transform.origin = pos
	
	# Check if boosting with spacebar
	var current_speed = forward_speed
	if Input.is_action_pressed("ui_accept"):  # Spacebar
		current_speed = boost_speed
		
	if Input.is_action_pressed("w"):
		apply_central_force(global_transform.basis * Vector3.LEFT * current_speed)
		if Input.is_action_pressed("a"):
			apply_torque(Vector3(0, 1, 0) * turn_strength)
		if Input.is_action_pressed("d"):
			apply_torque(Vector3(0, -1, 0) * turn_strength)
	
	# backward movement 
	if Input.is_action_pressed("s"):
		apply_central_force(global_transform.basis * Vector3.RIGHT * current_speed * 0.5)  
		if Input.is_action_pressed("a"):
			apply_torque(Vector3(0, -1, 0) * turn_strength)  # Reverse turning
		if Input.is_action_pressed("d"):
			apply_torque(Vector3(0, 1, 0) * turn_strength)  # Reverse turning
	
	var water_level = 0.0
	
	if $Floaty.global_transform.origin.y <= water_level:
		var depth = water_level - $Floaty.global_transform.origin.y
		apply_force(Vector3.UP * 20 * depth, $Floaty.global_transform.origin - global_transform.origin)
	if $Floaty2.global_transform.origin.y <= water_level:
		var depth = water_level - $Floaty2.global_transform.origin.y
		apply_force(Vector3.UP * 20 * depth, $Floaty2.global_transform.origin - global_transform.origin)
	if $Floaty3.global_transform.origin.y <= water_level:
		var depth = water_level - $Floaty3.global_transform.origin.y
		apply_force(Vector3.UP * 20 * depth, $Floaty3.global_transform.origin - global_transform.origin)
	if $Floaty4.global_transform.origin.y <= water_level:
		var depth = water_level - $Floaty4.global_transform.origin.y
		apply_force(Vector3.UP * 20 * depth, $Floaty4.global_transform.origin - global_transform.origin)
