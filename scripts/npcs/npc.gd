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

func _process(_delta: float) -> void:
	# If dialogue is active, keep accepting input regardless of player range.
	# This prevents the conversation from getting stuck if the boat drifts out.
	if DialogueManager.active and DialogueManager.current_npc == npc_id:
		prompt_ui.visible = false
		indicator.visible = false
		if Input.is_action_just_pressed("ui_accept"):
			get_viewport().set_input_as_handled()
			if DialogueManager.dialogueUI.typing:
				DialogueManager.dialogueUI.finish_line()
			else:
				DialogueManager.next_line(npc_id)
		return

	# Not in dialogue — only show prompt / handle input when in range
	if not player_in_range:
		prompt_ui.visible = false
		return

	if questPopup.visible:
		_update_indicator()
		return

	prompt_ui.visible = DialogueManager.has_new_lines(npc_id)
	DialogueManager.dialogueUI.hide_interaction_prompt()

	if Input.is_action_just_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		DialogueManager.start_dialogue(npc_id)

func _on_body_entered(body: Node3D) -> void:
	if not body is Boat:
		return
	var player = body.player
	if not player:
		return
	player_in_range = true
	if not DialogueManager.active and DialogueManager.has_new_lines(npc_id):
		prompt_ui.visible = true
		DialogueManager.dialogueUI.show_interaction_prompt()

func _on_body_exited(body: Node3D) -> void:
	if not body is Boat:
		return
	var player = body.player
	if not player:
		return
	player_in_range = false
	prompt_ui.visible = false
	# Don't hide the interaction prompt or kill dialogue if it's still active
	if not DialogueManager.active:
		DialogueManager.dialogueUI.hide_interaction_prompt()

func _on_quest_assigned(qid) -> void:
	if qid != quest_id:
		return
	var quest = QuestManager.get_quest(qid)
	if quest:
		if questPopup != null:
			questPopup.show_quest(quest.title, quest.description)

func _update_indicator(_active_quests = null):
	if indicator.visible == true:
		indicator.visible = false
