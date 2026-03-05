extends Node

var dialogueUI: dialogue_ui
var active: bool = false

func register_ui(ui):
	dialogueUI = ui

#structure: { npc_id: {quest_id: [dialogue_lines] } }

var dialogue_data: Dictionary = {
	"dock_npc": {
		"": [ "Have you gotten a hang of steering that boat yet?",
		"I know it's a rickety old thing, but it's good enough to keep you afloat in calm waters like these.",
		"That's not what you're here for, though, huh? I promised to teach you the basics!"
		],
		"tutorial_01": [
			"We'll start with something small - just catch a fish in this here lake.",
			"Talk to me again once you've gotten something to show for it!"
		]
	}
}

func start_dialogue(lines: Array):
	if dialogue_ui == null: 
		push_error("dialogueUI not registered properly")
		return
	active = true
	dialogueUI.start_dialogue(lines)
	
func end_dialogue():
	active = false

func get_dialogue(npc_id: String, quest_id: String = "") -> Array:
	if dialogue_data.has(npc_id):
		var npc_dialogue = dialogue_data[npc_id]
		if npc_dialogue.has(quest_id):
			return npc_dialogue[quest_id]
		else: 
			return npc_dialogue
	return []
