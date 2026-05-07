@tool
extends Node3D

@export var distance_to_move: float = 42
@export var possss: float
@export_tool_button("meow") var update_now = update.bind(possss)
@export_tool_button("readddy") var readddddddd = _ready


## this is a ring buffer
var sorted_children: Array[Node3D] 
var index: int = 0

func _ready() -> void:
	sorted_children = []
	for child in get_children():
		if child is Node3D:
			sorted_children.append(child)
	
	sorted_children.sort_custom(func (a: Node3D, b: Node3D): return a.position.z > b.position.z)
	index = 0

func update(camera_start: float):
	var bottom_camera : float = possss - fmod(possss, distance_to_move)
	#print("bottom camera ", bottom_camera)
	move_foward(possss, bottom_camera)

func move_foward(limit: float, bottom_camera: float):
	for _a in range(0, len(sorted_children)):
		var child = sorted_children[index]
		if child.position.z < limit:
			child.position.z = fmod(child.position.z, distance_to_move) + bottom_camera
		else:
			return
		index += 1
		index %= len(sorted_children)
