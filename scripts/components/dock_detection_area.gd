extends Area3D
class_name DockDetectionArea
## Dock Detection Area
## Handles boat docking with engine stop/start sounds
## Can be used for piers, docks, or any location where the boat "parks"

# ========================================
# SIGNALS
# ========================================

signal boat_docked(boat: Boat)
signal boat_undocked(boat: Boat)

# ========================================
# CONFIGURATION
# ========================================

@export var show_prompt: bool = true
@export var prompt_text: String = "Press E to interact"
@export var auto_stop_engine: bool = true  # Automatically stop engine when docking

# ========================================
# VARIABLES
# ========================================

var _docked_boat: Boat = null
var _prompt_label: Label = null

# ========================================
# INITIALIZATION
# ========================================

func _ready():
	# Connect collision detection signals
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Create prompt label if needed
	if show_prompt:
		_create_prompt_label()

func _create_prompt_label() -> void:
	_prompt_label = Label.new()
	_prompt_label.text = prompt_text
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_label.visible = false
	
	# Add to CanvasLayer so it's always on top
	var canvas = CanvasLayer.new()
	canvas.layer = 10
	add_child(canvas)
	
	var container = CenterContainer.new()
	container.anchors_preset = Control.PRESET_CENTER_BOTTOM
	container.offset_top = -100
	container.offset_bottom = -50
	container.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	canvas.add_child(container)
	container.add_child(_prompt_label)

# ========================================
# COLLISION DETECTION
# ========================================

func _on_body_entered(body: Node) -> void:
	if not body is Boat:
		return
	
	_docked_boat = body
	
	# Stop engine sounds
	if auto_stop_engine:
		_docked_boat.stop_engine_sounds()
	
	# Show prompt
	if _prompt_label:
		_prompt_label.visible = true
	
	boat_docked.emit(_docked_boat)

func _on_body_exited(body: Node) -> void:
	if not body is Boat:
		return
	
	if body == _docked_boat:
		# Start engine sounds
		if auto_stop_engine:
			_docked_boat.start_engine_sounds()
		
		# Hide prompt
		if _prompt_label:
			_prompt_label.visible = false
		
		boat_undocked.emit(_docked_boat)
		_docked_boat = null

# ========================================
# PUBLIC API
# ========================================

func is_boat_docked() -> bool:
	return _docked_boat != null

func get_docked_boat() -> Boat:
	return _docked_boat

## Manually trigger engine stop (for cutscenes, dialogues, etc.)
func force_stop_engine() -> void:
	if _docked_boat:
		_docked_boat.stop_engine_sounds()

## Manually trigger engine start
func force_start_engine() -> void:
	if _docked_boat:
		_docked_boat.start_engine_sounds()
        