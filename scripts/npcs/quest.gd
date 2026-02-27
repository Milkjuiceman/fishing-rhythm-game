extends Resource
class_name Quest

var id: String
var state = QuestManage.QuestState.NOT_STARTED
var requirements: Array = []
var rewards: Array = []
@export var reward_currency: int = 0
@export var reward_items: Array[Dictionary] = []

func check_requirements() -> bool:
	for requirement in requirements:
		if not requirement.is_met():
			return false
	return true

func apply_rewards() -> void:
	for reward in rewards:
		reward.apply()
		
