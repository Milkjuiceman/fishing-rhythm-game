extends Node3D
class_name Player

# Reference to the current vehicle (boat, etc.)
var current_vehicle: VehicleBase = null

# Detection area for interactions
@onready var detection_area: Area3D = null

func _ready():
	# Find the vehicle child
	for child in get_children():
		if child is VehicleBase:
			current_vehicle = child
			# Get detection area from vehicle
			detection_area = current_vehicle.get_detection_area()
			break
	
	if current_vehicle:
		current_vehicle.player = self

func _unhandled_input(event):
	if current_vehicle:
		current_vehicle._unhandled_input(event)

func _physics_process(delta):
	if current_vehicle:
		current_vehicle._physics_process(delta)

# Method for interacting with objects
func interact_with_nearest():
	if detection_area:
		var _overlapping_bodies = detection_area.get_overlapping_bodies()
		# Add aditional interaction logic here
		pass

# Method to switch vehicles 
func switch_vehicle(new_vehicle_scene: PackedScene):
	if current_vehicle:
		var old_position = current_vehicle.global_position
		var old_rotation = current_vehicle.rotation
		
		current_vehicle.queue_free()
		
		var new_vehicle = new_vehicle_scene.instantiate()
		add_child(new_vehicle)
		new_vehicle.global_position = old_position
		new_vehicle.rotation = old_rotation
		
		current_vehicle = new_vehicle
		current_vehicle.player = self
		detection_area = current_vehicle.get_detection_area()

# Scene transition - saves state and changes scene
func transition_to_scene(scene_path: String):
	BoatManager.save_player_state(self)
	get_tree().change_scene_to_file(scene_path)

# Get current position 
func get_current_position() -> Vector3:
	if current_vehicle:
		return current_vehicle.global_position
	return global_position

# Get current rotation 
func get_current_rotation() -> Vector3:
	if current_vehicle:
		return current_vehicle.rotation
	return rotation
