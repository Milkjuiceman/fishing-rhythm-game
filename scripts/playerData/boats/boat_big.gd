extends Boat
class_name BoatBig

func _ready():
	super._ready()
	forward_speed = 40
	boost_speed = 80
	turn_strength = 1.5


func _physics_process(_delta):
	super._physics_process(_delta)
	# Unique big boat behavior here
