extends Node3D
class_name NPC

@export var npc_id: String = "NPC"
@export var quest_id: String = ""
@export var dialogueUI: CanvasLayer
@export var questPopup: CanvasLayer

@onready var interaction_area: Area3D = $Area3D
@onready var prompt_ui: Sprite3D = $Prompt if has_node("Prompt") else null
@onready var indicator: Sprite3D = $Indicator if has_node("Indicator") else null

var player_in_range: bool = false

func _ready():
	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)
	QuestManager.quest_started.connect(_on_quest_assigned)
	QuestManager.active_quests_changed.connect(_update_indicator)
	_set_prompt(false)
	_set_indicator(true)

# ========================================
# HELPERS — safe setters
# ========================================

func _set_prompt(value: bool) -> void:
	if prompt_ui:
		prompt_ui.visible = value

func _set_indicator(value: bool) -> void:
	if indicator:
		indicator.visible = value

# ========================================
# PROCESS
# ========================================

func _process(_delta: float) -> void:
	# If dialogue is active for this NPC, keep accepting input regardless of range.
	if DialogueManager.active and DialogueManager.current_npc == npc_id:
		_set_prompt(false)
		_set_indicator(false)
		if Input.is_action_just_pressed("ui_accept"):
			get_viewport().set_input_as_handled()
			if DialogueManager.dialogueUI.typing:
				DialogueManager.dialogueUI.finish_line()
			else:
				DialogueManager.next_line(npc_id)
		return

	# Not in dialogue — only show prompt / handle input when in range
	if not player_in_range:
		_set_prompt(false)
		return

	if questPopup and questPopup.visible:
		_update_indicator()
		return

	_set_prompt(DialogueManager.has_new_lines(npc_id))
	DialogueManager.dialogueUI.hide_interaction_prompt()

	if Input.is_action_just_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		DialogueManager.start_dialogue(npc_id)

# ========================================
# COLLISION
# ========================================

func _on_body_entered(body: Node3D) -> void:
	if not body is Boat:
		return
	var player = body.player
	if not player:
		return
	player_in_range = true
	if not DialogueManager.active and DialogueManager.has_new_lines(npc_id):
		_set_prompt(true)
		DialogueManager.dialogueUI.show_interaction_prompt()

func _on_body_exited(body: Node3D) -> void:
	if not body is Boat:
		return
	var player = body.player
	if not player:
		return
	player_in_range = false
	_set_prompt(false)
	if not DialogueManager.active:
		DialogueManager.dialogueUI.hide_interaction_prompt()

# ========================================
# QUEST EVENTS
# ========================================

func _on_quest_assigned(qid) -> void:
	if qid != quest_id:
		return
	var quest = QuestManager.get_quest(qid)
	if quest and questPopup != null:
		questPopup.show_quest(quest.title, quest.description)

func _update_indicator(_active_quests = null):
	_set_indicator(false)
