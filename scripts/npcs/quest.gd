extends Resource
class_name Quest

@export var quest_id: String
@export var title: String
@export var description: String
@export var completed: bool = false
@export var reward_items: Dictionary = {}

var state = QuestManager.QuestState.NOT_STARTED
var requirements: Array = []
@export var reward_currency: int = 0

func check_requirements() -> bool:
	for requirement in requirements:
		if not requirement.is_met():
			return false
	return true

func apply_rewards() -> void:
	for reward in reward_items:
		reward.apply()
		
