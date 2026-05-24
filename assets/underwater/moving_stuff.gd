@tool
extends Node3D

var distance_to_move: float = 42 * 3

@export var debug_update_to_location: float
@export_tool_button("debug_update_to") var debug_update_now = update.bind(debug_update_to_location)
@export_tool_button("debug_readddy") var debug_readddddddd = _ready
@export_tool_button("debug_reset") var debug_reseter = _reset


## this is a ring buffer
var sorted_children: Array[Node3D] 
var index: int = 0

func _ready() -> void:
	sorted_children = []
	for child in get_children():
		if child is Node3D:
			sorted_children.append(child)
	
	sorted_children.sort_custom(func (a: Node3D, b: Node3D): return a.position.z < b.position.z)
	index = 0

func update(camera_start: float):
	#print(sorted_children)
	move_foward(camera_start)

func move_foward(limit: float):
	var next_rung = (floori(limit / distance_to_move) + 1) * distance_to_move
	for _a in range(0, len(sorted_children)):
		var child = sorted_children[index]
		#print(child.position.z)
		#print(child.position.z)
		if child.position.z < limit:
			#print("lt")
			var offset_from_rung = fmod(child.position.z, distance_to_move)
			child.position.z = next_rung + offset_from_rung
		else:
			return # dont need to itterate anymore cause the rest will be larger
		index += 1
		index %= len(sorted_children)

func _reset():
	for _a in range(0, len(sorted_children)):
		var child = sorted_children[_a]
		var offset_from_rung = fmod(child.position.z, distance_to_move)
		#print(child.position.z, " ", offset_from_rung)
		child.position.z = offset_from_rung
	_ready()
