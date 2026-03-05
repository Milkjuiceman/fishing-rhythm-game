extends Node3D
class_name NPC

@export var npc_id: String = "NPC"
@export var quest_id: String = ""
@export var dialogueUI: CanvasLayer
@export var questPopup: CanvasLayer

@onready var interaction_area: Area3D = $Area3D
@onready var prompt_ui: Sprite3D = $Prompt
@onready var indicator: Sprite3D = $Indicator

var player_in_range: bool = false

func _ready():
	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)
	QuestManager.quest_started.connect(_on_quest_assigned)
	QuestManager.active_quests_changed.connect(_update_indicator)

	prompt_ui.visible = false
	indicator.visible = true
	
func _process(delta: float) -> void:
	if questPopup.visible:
		_update_indicator()
		return
	if player_in_range and Input.is_action_just_pressed("ui_accept"):
		prompt_ui.visible = false
		if DialogueManager.active:
			DialogueManager.next_line(npc_id)
		else:
			DialogueManager.start_dialogue(npc_id)

func _on_body_entered(body: Node3D) -> void:
	if not body is Boat:
		return
	var player = body.player
	if not player:
		return
	player_in_range = true
	prompt_ui.visible = true
	
func _on_body_exited(body: Node3D) -> void:
	if not body is Boat:
		return
	var player = body.player
	if not player:
		return
	player_in_range = false
	prompt_ui.visible = false

func _on_quest_assigned(qid) -> void:
	if qid != quest_id:
		return
	var quest = QuestManager.get_quest(qid)
	if quest:
		print_debug("[NPC]: assigned quest: ", quest.title)
		if questPopup != null:
			questPopup.show_quest(quest.title, quest.description)

func _update_indicator(active_quests = null):
	if indicator.visible == true:
		indicator.visible = false
