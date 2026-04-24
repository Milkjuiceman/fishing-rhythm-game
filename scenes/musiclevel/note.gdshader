shader_type spatial;


uniform sampler2D noise_texture;
uniform float smoothness : hint_range(0.0, 1.0, 0.);
uniform float speed = 1.0;
uniform float seed;
uniform float vertex_speed = 0.01;
uniform float displacement_strength : hint_range(0.0, 1.0, 0.);
uniform vec3 lane_color : source_color;


varying vec3 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float height = texture(noise_texture, VERTEX.xz * smoothness + vec2(TIME * vertex_speed, seed)).r;
	VERTEX += NORMAL * height * displacement_strength;
}

uniform sampler2D ior_gradient : repeat_disable;
render_mode blend_add;
render_mode cull_disabled;
void fragment() {
	ROUGHNESS = 0.1;
	float a = 1. - dot(normalize(NORMAL), normalize(VIEW));
	ALBEDO = texture(ior_gradient, vec2(a, 0.5)).rgb;
	//ALBEDO *= ALBEDO;
}
