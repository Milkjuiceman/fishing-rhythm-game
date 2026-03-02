extends RigidBody3D
class_name VehicleBase
## Vehicle Base Class
## Abstract base class for all player-controllable vehicles (boats, etc.)
## Child classes override movement logic, input handling, and physics

# ========================================
# REFERENCES
# ========================================

# Reference to parent player node
var player: Player = null

# ========================================
# MOVEMENT PARAMETERS
# ========================================

# Override these values in child classes for vehicle-specific behavior
var forward_speed = 50      # Normal movement speed
var boost_speed = 100       # Boosted movement speed
var turn_strength = 2.0     # Turning torque strength

# ========================================
# LIFECYCLE HOOKS
# ========================================

# Initialize vehicle (override in child classes for custom setup)
func _ready():
	pass

# Handle input events (override in child classes)
func _unhandled_input(_event):
	pass

# Process physics and movement (override in child classes)
func _physics_process(_delta):
	pass

# ========================================
# ABSTRACT METHODS
# ========================================

# Get the vehicle's interaction detection area (must override in child classes)
func get_detection_area() -> Area3D:
	return null
