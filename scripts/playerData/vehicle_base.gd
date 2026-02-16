extends RigidBody3D
class_name VehicleBase

# Reference to parent player
var player: Player = null

# Override these in child classes
var forward_speed = 50
var boost_speed = 100
var turn_strength = 2.0

func _ready():
	pass

# Child classes should override this
func _unhandled_input(_event):
	pass

# Child classes should override this
func _physics_process(_delta):
	pass

# Get the detection area - override in child classes
func get_detection_area() -> Area3D:
	return null
