shader_type canvas_item;

uniform sampler2D text: filter_nearest;

void fragment() {
	COLOR = texture(text, UV);
}
