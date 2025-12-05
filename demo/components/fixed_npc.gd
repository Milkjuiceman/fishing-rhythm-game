extends CharacterBody3D

@onready var interact_area = $Area3D
var in_range = false
@onready var interact_prompt = get_node("../UI/Label")
@onready var dialogue_node = get_node("../UI/Label")

func _ready():
	if interact_area == null:
		push_error("frog_npc: $Area3D not found. Make sure Area3D exists as a child named Area3D.")
		return
	interact_area.connect("body_entered", Callable(self, "_on_area_entered"))
	interact_area.connect("body_exited", Callable(self, "_on_area_exited"))
	interact_prompt.visible = false
	#print("Frog ready, area=", interact_area)

	
func _on_area_entered(body):
	#print("Area entered by:", body)
	if body.name == "Player":
		#print("Entered frog area, prompt node =", interact_prompt, " visible =", interact_prompt.visible)
		in_range = true
		if interact_prompt:
			interact_prompt.visible = true
		
func _on_area_exited(body):
	if body.name == "Player":
		in_range = false
		if interact_prompt:
			interact_prompt.visible = false

func _process(delta: float) -> void:
	if in_range and Input.is_action_just_pressed("interact"):
		if dialogue_node and dialogue_node.has_method("start_dialogue"):
			dialogue_node.start_dialogue([
				"It's a beautiful day for fishing, huh?",
				"Once you hook a fish, \njust tap to the beat.",
				"Don't worry, you'll get the hang of it!"
			])
		else:
			push_warning("Dialogue node/method missing. Expected UI/Dialogue.start_dialogue(Array)")
