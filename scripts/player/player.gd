extends Node3D
class_name Player
## Player Controller
## Container for vehicle-based gameplay with delegated input and physics
## State management handled by GameStateManager for persistence across scenes

# ========================================
# VARIABLES
# ========================================

# Current vehicle reference
var current_vehicle: VehicleBase = null

# Detection area for interactions (delegated from vehicle)
@onready var detection_area: Area3D = null

# ========================================
# INITIALIZATION
# ========================================

func _ready() -> void:
	_initialize_vehicle()

# Find and setup the vehicle child node
func _initialize_vehicle() -> void:
	# Search for VehicleBase child
	for child in get_children():
		if child is VehicleBase:
			current_vehicle = child
			detection_area = current_vehicle.get_detection_area()
			current_vehicle.player = self
			break
	
	# Warn if no vehicle found
	if not current_vehicle:
		push_warning("Player has no vehicle attached!")

# ========================================
# INPUT & PHYSICS DELEGATION
# ========================================

# Delegate input handling to current vehicle
func _unhandled_input(event: InputEvent) -> void:
	if current_vehicle:
		current_vehicle._unhandled_input(event)

# Delegate physics processing to current vehicle
func _physics_process(delta: float) -> void:
	if current_vehicle:
		current_vehicle._physics_process(delta)

# ========================================
# INTERACTION SYSTEM
# ========================================

# Interact with the nearest NPC or interactable object in range
func interact_with_nearest() -> void:
	if not detection_area:
		return
	
	var overlapping_bodies = detection_area.get_overlapping_bodies()
	
	# Find closest interactable object
	var closest_distance: float = INF
	var closest_interactable: Node = null
	
	for body in overlapping_bodies:
		if body.is_in_group("npc") or body.is_in_group("interactable"):
			var distance = global_position.distance_to(body.global_position)
			if distance < closest_distance:
				closest_distance = distance
				closest_interactable = body
	
	# Trigger interaction on closest object
	if closest_interactable and closest_interactable.has_method("interact"):
		closest_interactable.interact(self)

# ========================================
# SCENE TRANSITIONS
# ========================================

# Transition to a new scene with optional spawn point
func transition_to_scene(scene_path: String, spawn_point: String = "") -> void:
	GameStateManager.transition_to_scene(scene_path, spawn_point)

# ========================================
# GETTERS
# ========================================

# Get current world position (from vehicle or player)
func get_current_position() -> Vector3:
	if current_vehicle:
		return current_vehicle.global_position
	return global_position

# Get current rotation (from vehicle or player)
func get_current_rotation() -> Vector3:
	if current_vehicle:
		return current_vehicle.rotation
	return rotation

# Get current vehicle scene path
func get_vehicle_type() -> String:
	if current_vehicle and current_vehicle.scene_file_path:
		return current_vehicle.scene_file_path
	return ""
