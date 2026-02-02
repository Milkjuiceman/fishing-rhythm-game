extends RigidBody3D
var mouse_movement = Vector2()
var forward_speed = 50  # Normal forward speed
var boost_speed = 100  # Speed when boosting 
var turn_strength = 1.0
var locked_y_position = 0.0
@onready var detection_area = $DetectionArea

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	axis_lock_angular_x = true
	axis_lock_angular_z = true
	
	locked_y_position = global_transform.origin.y

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
func _unhandled_input(event):
	if event is InputEventMouseMotion:
		mouse_movement += event.relative
		
func _physics_process(_delta):
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

func transition_to_scene(scene_path: String):
	BoatManager.save_boat_state(self)
	get_tree().change_scene_to_file(scene_path)
