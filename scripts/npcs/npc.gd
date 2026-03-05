extends Node3D
class_name NPC

@export var npc_id: String = "NPC"
@export var quest_id: String = ""
@export var dialogueUI: CanvasLayer

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
	if dialogueUI.active: 
		return
	if player_in_range and Input.is_action_just_pressed("ui_accept"):
		_start_dialogue()

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
	
func _start_dialogue():
	var lines = DialogueManager.get_dialogue(npc_id, "")
	if lines.size() > 0:
		DialogueManager.start_dialogue(lines)
		request_quest()

func request_quest():
	return
