extends RigidBody3D

var mouse_movement = Vector2()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
func _unhandled_input(event):
	if event is InputEventMouseMotion:
		mouse_movement += event.relative
		
func _physics_process(_delta):
	if mouse_movement != Vector2():
		$H.rotation_degrees.y += -mouse_movement.x
		mouse_movement = Vector2()
		
	if Input.is_action_pressed("w"):
		apply_central_force(global_transform.basis * Vector3.LEFT * 20)
		if Input.is_action_pressed("a"):
			apply_torque(Vector3(0, 1, 0))
		if Input.is_action_pressed("d"):
			apply_torque(Vector3(0, -1, 0))
	elif Input.is_action_pressed("s"):
		apply_central_force(global_transform.basis * Vector3.RIGHT * 10)
		if Input.is_action_pressed("a"):
			apply_torque(Vector3(0, 1, 0))
		if Input.is_action_pressed("d"):
			apply_torque(Vector3(0, -1, 0))
			
	if $Floaty.global_transform.origin.y <=0:
		apply_force(Vector3.UP * 20 * -$Floaty.global_transform.origin, $Floaty.global_transform.origin - global_transform.origin)
	if $Floaty2.global_transform.origin.y <=0:
		apply_force(Vector3.UP * 20 * -$Floaty2.global_transform.origin, $Floaty2.global_transform.origin - global_transform.origin)
	if $Floaty3.global_transform.origin.y <=0:
		apply_force(Vector3.UP * 20 * -$Floaty3.global_transform.origin, $Floaty3.global_transform.origin - global_transform.origin)
	if $Floaty4.global_transform.origin.y <=0:
		apply_force(Vector3.UP * 20 * -$Floaty4.global_transform.origin, $Floaty4.global_transform.origin - global_transform.origin)
