extends Node3D

signal interaction_started(lines: Array)
@onready var interact_area = $NPCzone
var in_range := false

func _ready():
	interact_area.body_entered.connect(_on_body_entered)
	interact_area.body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.is_in_group("player"):
		in_range = true
		body.set_current_npc(self)
		
func _on_body_exited(body):
	if body.is_in_group("player"):
		in_range = false
		body.clear_current_npc(self)

func try_interact():
	if not in_range:
		return
	emit_signal("interaction_started", [
		"",
		"It's a beautiful day for fishing, huh?",
		"Once you hook a fish,\njust tap to the rhythm.",
        "Don't worry, you'll get the hang of it!"
	])
