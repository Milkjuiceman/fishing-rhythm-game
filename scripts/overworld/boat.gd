extends RigidBody3D

@export var ui_node: NodePath
@onready var ui = get_node(ui_node)

var mouse_movement = Vector2()
var current_npc: Node = null
var in_range: bool = false

@onready var fish_notification = $"../FishNotification"  # If FishNotification is a sibling node
@onready var detection_area = $DetectionArea  # Area3D child node

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	detection_area.body_entered.connect(_on_area_entered)
	detection_area.body_exited.connect(_on_area_exited)
	
	# Hide notification at start
	if fish_notification:
		fish_notification.visible = false

func _input(event: InputEvent):
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if event.is_action_pressed("interact") and current_npc and in_range:
		if current_npc.has_method("try_interact"):
			current_npc.try_interact()
	
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

# Fish and NPC notification area detection
func _on_area_entered(body):
	if body.name == "RipplingWaterArea": 
		show_fish_notification()
	if body.is_in_group("npc"):
		set_current_npc(body)
		
func _on_area_exited(body):
	if body.is_in_group("npc"):
		clear_current_npc(body)

func show_fish_notification():
	if fish_notification:
		fish_notification.visible = true
		# Notification will stay visible for 3 seconds
		await get_tree().create_timer(3.0).timeout
		fish_notification.visible = false

func set_current_npc(npc):
	current_npc = npc
	in_range = true
	if ui:
		ui.player_enters_interzone()
	var callable_dialogue = Callable(ui, "start_dialogue")
	if not npc.is_connected("interaction_started", callable_dialogue):
		npc.connect("interaction_started", callable_dialogue)
	
func clear_current_npc(npc):
	if current_npc == npc:
		current_npc = null
		in_range = false
		if ui:
			ui.player_exits_interzone()
		
