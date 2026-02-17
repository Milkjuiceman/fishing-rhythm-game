extends VehicleBase
class_name Boat
## Small Boat Controller
## Handles player movement, physics-based buoyancy, collision prevention, and camera rotation

# ========================================
# VARIABLES
# ========================================

var mouse_movement = Vector2()
var locked_y_position = 0.0

@onready var detection_area = $DetectionArea

# ========================================
# INITIALIZATION
# ========================================

func _ready():
	super._ready()
	
	# Configure boat performance stats
	forward_speed = 50
	boost_speed = 100
	turn_strength = 5.0
	
	# Capture mouse for camera control
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# Lock rotation axes to prevent tilting
	axis_lock_angular_x = true
	axis_lock_angular_z = true
	
	# Lock boat to water surface height
	locked_y_position = global_transform.origin.y
	
	# Enable collision monitoring
	contact_monitor = true
	max_contacts_reported = 4
	
	# Configure physics damping to reduce erratic movement
	angular_damp = 8.0  # Prevents wild spinning from collisions
	linear_damp = 1.0   # Reduces bouncing
	continuous_cd = true  # Prevents clipping through walls

# ========================================
# PUBLIC METHODS
# ========================================

# Update water surface lock height (called after spawning or scene transitions)
func update_water_lock():
	locked_y_position = global_transform.origin.y

# Return detection area for interaction system
func get_detection_area() -> Area3D:
	return detection_area

# ========================================
# INPUT HANDLING
# ========================================

# Capture mouse movement for camera rotation
func _unhandled_input(event):
	if event is InputEventMouseMotion:
		mouse_movement += event.relative

# ========================================
# PHYSICS & MOVEMENT
# ========================================

func _physics_process(_delta):
	# Skip physics when game is paused
	if get_tree().paused:
		return
	
	# --- Camera Rotation ---
	# Apply accumulated mouse movement to camera
	if mouse_movement != Vector2():
		$H.rotation_degrees.y += -mouse_movement.x
		mouse_movement = Vector2()
	
	# --- Lock Y Position ---
	# Keep boat at water surface level
	var pos = global_transform.origin
	pos.y = locked_y_position
	global_transform.origin = pos
	
	# --- Collision Spin Prevention ---
	# Limit how fast the boat can spin from impacts
	var max_angular_velocity = 3.0
	if abs(angular_velocity.y) > max_angular_velocity:
		angular_velocity.y = sign(angular_velocity.y) * max_angular_velocity
	
	# Ensure no unwanted rotation on locked axes
	angular_velocity.x = 0
	angular_velocity.z = 0
	
	# --- Speed Control ---
	# Check for boost input (spacebar)
	var current_speed = forward_speed
	if Input.is_action_pressed("ui_accept"):
		current_speed = boost_speed
	
	# --- Forward Movement (W) ---
	# Apply forward force and handle turning
	if Input.is_action_pressed("w"):
		apply_central_force(global_transform.basis * Vector3.LEFT * current_speed)
		if Input.is_action_pressed("a"):
			apply_torque(Vector3(0, 1, 0) * turn_strength)
		if Input.is_action_pressed("d"):
			apply_torque(Vector3(0, -1, 0) * turn_strength)
	
	# --- Backward Movement (S) ---
	# Apply reverse force with reversed turning
	if Input.is_action_pressed("s"):
		apply_central_force(global_transform.basis * Vector3.RIGHT * current_speed * 0.5)
		if Input.is_action_pressed("a"):
			apply_torque(Vector3(0, -1, 0) * turn_strength)
		if Input.is_action_pressed("d"):
			apply_torque(Vector3(0, 1, 0) * turn_strength)
	
	# --- Buoyancy System ---
	# Apply upward force based on how deep each floaty point is submerged
	var water_level = 0.0
	
	# Floaty point 1
	if $Floaty.global_transform.origin.y <= water_level:
		var depth = water_level - $Floaty.global_transform.origin.y
		apply_force(Vector3.UP * 20 * depth, $Floaty.global_transform.origin - global_transform.origin)
	
	# Floaty point 2
	if $Floaty2.global_transform.origin.y <= water_level:
		var depth = water_level - $Floaty2.global_transform.origin.y
		apply_force(Vector3.UP * 20 * depth, $Floaty2.global_transform.origin - global_transform.origin)
	
	# Floaty point 3
	if $Floaty3.global_transform.origin.y <= water_level:
		var depth = water_level - $Floaty3.global_transform.origin.y
		apply_force(Vector3.UP * 20 * depth, $Floaty3.global_transform.origin - global_transform.origin)
	
	# Floaty point 4
	if $Floaty4.global_transform.origin.y <= water_level:
		var depth = water_level - $Floaty4.global_transform.origin.y
		apply_force(Vector3.UP * 20 * depth, $Floaty4.global_transform.origin - global_transform.origin)
