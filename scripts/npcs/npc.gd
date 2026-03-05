extends Node3D
class_name NPC

@export var npc_id: String = "NPC"
@export var quest_id: String = ""

@onready var interaction_area: Area3D = $Area3D

@onready var prompt_ui: Sprite3D = $Prompt
@onready var indicator: Sprite3D = $Indicator

var player_in_range: bool = false

signal requested(quest_id: String)

func _ready():
	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)
	indicator.visible = true
	prompt_ui.visible = false
	
func _process(delta: float) -> void:
	if player_in_range and Input.is_action_just_pressed("ui_accept"):
		if quest_id != "":
			request_quest()
		else:
			print_debug("[%s]: Player talked to NPC (no quest)" % npc_id)

func _on_body_entered(body: Node3D) -> void:
	if not body is Boat:
		return
	var player = body.player
	if not player:
		return
	player_in_range = true
	prompt_ui.visible = true
	indicator.visible = false
	
func _on_body_exited(body: Node3D) -> void:
	if not body is Boat:
		return
	var player = body.player
	if not player:
		return
	player_in_range = false
	prompt_ui.visible = false
	indicator.visible = true

func request_quest():
	emit_signal("requested", quest_id)
