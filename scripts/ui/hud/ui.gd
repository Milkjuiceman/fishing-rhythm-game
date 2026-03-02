extends CanvasLayer
## UI Controller
## Handles interaction prompts and dialogue system
## Manages dialogue box visibility, text progression, and player interaction cues

# ========================================
# NODE REFERENCES
# ========================================

@onready var interact_prompt = $prompt
@onready var dialogue_box = $dialoguebox
@onready var dialogue_text = $dialoguebox/textbox

# ========================================
# VARIABLES
# ========================================

var player_in_range := false
var dialogue_open := false
var dialogue_lines: Array = []
var current_line := 0

# ========================================
# INITIALIZATION
# ========================================

func _ready():
	# Allow UI to function during pause
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Hide UI elements by default
	dialogue_box.visible = false
	interact_prompt.visible = false

# ========================================
# PROMPT CONTROL
# ========================================

# Show interaction prompt when player enters range
func show_prompt():
	player_in_range = true
	_update_prompt()

# Hide interaction prompt when player leaves range
func hide_prompt():
	player_in_range = false
	_update_prompt()

# Update prompt visibility based on player proximity and dialogue state
func _update_prompt():
	interact_prompt.visible = player_in_range and not dialogue_open

# ========================================
# DIALOGUE CONTROL
# ========================================

# Begin dialogue sequence with provided lines
func start_dialogue(lines: Array):
	# Prevent starting dialogue if already active
	if dialogue_open:
		return
	
	# Initialize dialogue state
	dialogue_lines = lines
	current_line = 0
	dialogue_open = true
	dialogue_box.visible = true
	
	# Display first line (deferred to ensure UI is ready)
	call_deferred("_show_current_line")
	_update_prompt()

# Progress to next dialogue line
func advance_dialogue():
	# Only advance if dialogue is active
	if not dialogue_open:
		return
	
	current_line += 1
	
	# Show next line or close if finished
	if current_line < dialogue_lines.size():
		_show_current_line()
	else:
		close_dialogue()

# Close dialogue and return to normal state
func close_dialogue():
	dialogue_open = false
	dialogue_box.visible = false
	_update_prompt()

# ========================================
# QUERY METHODS
# ========================================

# Check if dialogue is currently active
func is_dialogue_open() -> bool:
	return dialogue_open

# ========================================
# INTERNAL METHODS
# ========================================

# Display the current dialogue line in the text box
func _show_current_line():
	if dialogue_lines.size() > 0:
		dialogue_text.text = dialogue_lines[current_line]
