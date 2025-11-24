extends RigidBody3D

var mouse_movement = Vector2()

@onready var fish_notification = $"../FishNotification"  # If FishNotification is a sibling node
@onready var detection_area = $DetectionArea  # Area3D child node

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	$DetectionArea.area_entered.connect(_on_area_entered)
	
	# Hide notification at start
	if fish_notification:
		fish_notification.visible = false

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
			
	if $Floaty.global_transform.origin.y <= 0:
		apply_force(Vector3.UP * 20 * -$Floaty.global_transform.origin.y, $Floaty.global_transform.origin - global_transform.origin)
	if $Floaty2.global_transform.origin.y <= 0:
		apply_force(Vector3.UP * 20 * -$Floaty2.global_transform.origin.y, $Floaty2.global_transform.origin - global_transform.origin)
	if $Floaty3.global_transform.origin.y <= 0:
		apply_force(Vector3.UP * 20 * -$Floaty3.global_transform.origin.y, $Floaty3.global_transform.origin - global_transform.origin)
	if $Floaty4.global_transform.origin.y <= 0:
		apply_force(Vector3.UP * 20 * -$Floaty4.global_transform.origin.y, $Floaty4.global_transform.origin - global_transform.origin)

# Fish notification area detection
func _on_area_entered(area):
	# Check if the area is the RipplingWater Area3D
	if area.name == "Area3D": 
		show_fish_notification()

func show_fish_notification():
	if fish_notification:
		fish_notification.visible = true
		# Notification will stay visible for 3 seconds
		await get_tree().create_timer(3.0).timeout
		fish_notification.visible = false
