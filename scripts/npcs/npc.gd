extends Node3D
class_name NPC

@export var npc_id: String
@export var interactable: bool = true # true by default, disabled NPCs should be false

signal interacted(npc_id)

var player_in_range: bool = false

func _ready():
	$interact_zone.body_entered.connect(_on_body_entered)
	$interact_zone.body_exited.connect(_on_body_exited)
	
func _on_body_entered(body):
	if body.is_in_group("player"):
		player_in_range = true
	
func _on_body_exited(body):
	if body.is_in_group("player"):
		player_in_range = false

func interact():
	emit_signal("interacted")
