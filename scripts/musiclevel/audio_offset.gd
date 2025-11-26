extends HSlider

@export var controls_audio_offset: bool = true

@onready var referee := get_tree().get_first_node_in_group("Rhythm")
@onready var value_label := $OffsetValue

var label_text := ""   # will store the original label text
var format_string = "%s%.1f ms"
var actual_string = ""

func _ready() -> void:
	label_text = value_label.text
	# Initialize slider position based on mode
	if controls_audio_offset:
		value = referee.audio_offset
	else:
		value = referee.input_offset
		
	actual_string = format_string % [label_text, value * 1000.0]
	value_label.text = str(actual_string)
	connect("value_changed", _on_value_changed)

func _on_value_changed(v):
	if controls_audio_offset:
		referee.audio_offset = v
	else:
		referee.input_offset = v
		
	actual_string = format_string % [label_text, value * 1000.0]
	value_label.text = str(actual_string)
		
