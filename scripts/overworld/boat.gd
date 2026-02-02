extends RigidBody3D

var nearby_npc: Node = null
var mouse_movement = Vector2()
@onready var fish_notification = $"../FishNotification"  # If FishNotification is a sibling node
@onready var detection_area = $DetectionArea  # Area3D child node
@onready var ui = $"../UI"

func _ready():
	detection_area.body_entered.connect(_on_area_entered)
	detection_area.body_exited.connect(_on_area_exited)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	process_mode = Node.PROCESS_MODE_ALWAYS
	if fish_notification:
		fish_notification.visible = false

		
func _unhandled_input(event):
	if event is InputEventMouseMotion:
		mouse_movement += event.relative
		
func _physics_process(_delta):
	if get_tree().paused:
		return
		
	if mouse_movement != Vector2():
		$H.rotation_degrees.y += -mouse_movement.x
		mouse_movement = Vector2()
		
	if Input.is_action_pressed("w"):
		apply_central_force(global_transform.basis * Vector3.LEFT * 20)
	elif Input.is_action_pressed("s"):
		apply_central_force(global_transform.basis * Vector3.RIGHT * 10)
	if Input.is_action_pressed("a"):
		apply_torque(Vector3(0, 1, 0))
	elif Input.is_action_pressed("d"):
		apply_torque(Vector3(0, -1, 0))

	if $Floaty.global_transform.origin.y <= 0:
		apply_force(Vector3.UP * 20 * -$Floaty.global_transform.origin.y, $Floaty.global_transform.origin - global_transform.origin)
	if $Floaty2.global_transform.origin.y <= 0:
		apply_force(Vector3.UP * 20 * -$Floaty2.global_transform.origin.y, $Floaty2.global_transform.origin - global_transform.origin)
	if $Floaty3.global_transform.origin.y <= 0:
		apply_force(Vector3.UP * 20 * -$Floaty3.global_transform.origin.y, $Floaty3.global_transform.origin - global_transform.origin)
	if $Floaty4.global_transform.origin.y <= 0:
		apply_force(Vector3.UP * 20 * -$Floaty4.global_transform.origin.y, $Floaty4.global_transform.origin - global_transform.origin)

	if Input.is_action_just_pressed("interact"):
		if nearby_npc and not ui.is_dialogue_open():
			ui.start_dialogue(nearby_npc.npc_lines)
		elif ui.is_dialogue_open():
			ui.advance_dialogue()
	
	if Input.is_action_just_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		
# Fish and NPC notification area detection
func _on_area_entered(body):
	if body == self:
		return
	if body.name == "RipplingWaterArea": 
		show_fish_notification()
	elif body.is_in_group("npc"):
		nearby_npc = body
		ui.show_prompt()

func _on_area_exited(body):
	if body.is_in_group("npc") and nearby_npc == body:
		nearby_npc = null
		ui.hide_prompt()

func show_fish_notification():
	if fish_notification:
		fish_notification.visible = true
		# Notification will stay visible for 3 seconds
		await get_tree().create_timer(3.0).timeout
		fish_notification.visible = false
