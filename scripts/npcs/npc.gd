extends Node3D
class_name NPC

@export var npc_name: String = "NPC"
@export var quest_id: String = ""

signal quest_started(quest_id: String)
signal quest_completed(quest_id: String)
signal quest_turned_in(quest_id: String)

var current_quest: Quest = null
var player_in_area: bool = false
var player_instance: Player = null

func _ready() -> void:
	if quest_id != "" and QuestManage.has_quest(quest_id):
		current_quest = QuestManage.get_quest(quest_id)
	var area = $interact_zone
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node) -> void:
	if body is Player:
		player_in_area = true
		player_instance = body
		print("player entered interaction area " % npc_name)
	
func _on_body_exited(body: Node) -> void:
	if body is Player:
		player_in_area = false
		player_instance = null
		
func _process(delta: float) -> void:
	if player_in_area and Input.is_action_just_pressed("ui_accept"):
		interact(player_instance)

func interact(player) -> void:
	if current_quest == null:
		return
	if current_quest.is_completed():
		emit_signal("quest_turned_in", current_quest.quest_id)
		give_rewards(player)
	elif not current_quest.is_active():
		current_quest.activate()
		emit_signal("quest_started", current_quest.quest_id)
	else:
		print("[npc]: requirements not met yet, keep fishing!!!")

func give_rewards(player):
	if current_quest == null:
		return

	if current_quest.reward_currency > 0:
		InventoryManage.add_currency(current_quest.reward_currency)
		print("[NPC Reward] Added currency:", current_quest.reward_currency)

	for reward in current_quest.reward_items:
		var item_id = reward.get("item_id", "")
		var rarity = reward.get("rarity", "")
		var amount = reward.get("amount", 1)
		if item_id != "":
			InventoryManage.add_item(item_id, rarity, amount)
			print("[npc reward] addde item:", item_id, "| rarity:", rarity, "| amount:", amount)
