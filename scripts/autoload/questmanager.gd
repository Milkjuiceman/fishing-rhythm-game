extends Node

signal quest_started(quest_id)
signal quest_completed(quest_id)
signal quest_turnedin(quest_id)

var definitions: Dictionary = {}

enum states {
	NOT_STARTED,
	ACTIVE,
	COMPLETED,
	TURNED_IN
}

var quests: Dictionary = {} # id -> quest

func _ready():
	pass
	
func init_quests():
	pass
