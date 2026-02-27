shader_type spatial;

uniform sampler2D noise_texture;
uniform float smoothness : hint_range(0.0, 1.0, 0.01);
uniform float speed = 1.0;
uniform float seed;
uniform float displacement_strength : hint_range(0.0, 1.0, 0.1);
uniform vec3 lane_color : source_color;

varying vec3 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float height = texture(noise_texture, VERTEX.xz * smoothness + vec2(TIME * 0.01)).r;
	VERTEX += NORMAL * height * displacement_strength;
}

float fresnel(vec3 normal, mat4 camera_matrix) {
	vec3 view_direction_world = (camera_matrix * vec4(0.0, 0.0, 1.0, 0.0)).xyz;
	vec3 normal_world = (camera_matrix * vec4(normal, 0.0)).xyz;
	
	float fresnel = dot(view_direction_world, normal_world);
	fresnel = clamp(abs(fresnel), 0.0, 2.5);
	return 0.8 - fresnel;
}

void fragment() {
	float fresnel = fresnel(NORMAL, VIEW_MATRIX);
	ROUGHNESS = 0.0;
	vec3 black = vec3(0.0, 0.0, 0.0);

    float t = (sin(TIME * speed) + 1.0) / 2.0;
	float r = fract(sin(seed * 12.9898) * 43758.5453);

    ALBEDO = mix(black, lane_color, t * r);
	ALPHA = fresnel;
}
