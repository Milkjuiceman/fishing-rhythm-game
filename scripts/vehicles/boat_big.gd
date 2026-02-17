extends Boat
class_name BoatBig
## Big Boat Controller
## Slower but more powerful variant of the base boat with stronger turning

# ========================================
# INITIALIZATION
# ========================================

func _ready():
	super._ready()
	
	# Configure big boat performance (slower but stronger)
	forward_speed = 40   # Reduced speed for larger vessel
	boost_speed = 80     # Lower max speed compared to small boat
	turn_strength = 7    # Increased turning power to compensate for size

# ========================================
# PHYSICS & MOVEMENT
# ========================================

func _physics_process(_delta):
	super._physics_process(_delta)
	
	# Add unique big boat behaviors here (heavier feel, more momentum, etc.)
