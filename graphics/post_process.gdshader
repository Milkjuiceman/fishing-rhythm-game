shader_type spatial;
render_mode blend_mix, depth_prepass_alpha, cull_disabled, unshaded, depth_test_disabled, depth_draw_always;

uniform sampler2D screen_texture : hint_screen_texture;
uniform sampler2D depth_texture : hint_depth_texture;
uniform float outline_offset : hint_range(0.0, 0.01, 0.0001);
uniform float outline_strength = 160.;
uniform vec3 fog_color : source_color;
uniform vec3 outline_color : source_color;
uniform float fog_start;
uniform float fog_width;

void vertex() {
	POSITION = vec4(UV*2. - vec2(1.), 0., 1.0);
}

float sample_linear_depth_at(vec2 uv, mat4 inv_projection_matrix) {
	float depth = texture(depth_texture, uv).x;
	float linear_depth = depth == 0. ? 10000000000. : inv_projection_matrix[2][3] / depth;
	linear_depth += inv_projection_matrix[3][3];
	return linear_depth;
}

const float x_dis = 1./384.;
const float y_dis = 1./216.;

float compute_outline_amount(float depth, vec2 screen_uv, mat4 inv_projection_matrix, out float avg_depth) {
	float ab = sample_linear_depth_at(screen_uv - vec2(x_dis, 0.), inv_projection_matrix);
	float ba = sample_linear_depth_at(screen_uv - vec2(0, y_dis), inv_projection_matrix);
	float bb = depth;
	float cb = sample_linear_depth_at(screen_uv + vec2(x_dis, 0.), inv_projection_matrix);
	float bc = sample_linear_depth_at(screen_uv + vec2(0, y_dis), inv_projection_matrix);
	
	avg_depth = ab + cb + ba + bc;
	avg_depth /= 4.;
	float side = depth - avg_depth;
	
	return clamp((side/depth-outline_offset)*outline_strength, 0., 1.);
}

float compute_fog_amount(float depth) {
	return 1. - exp(max(depth / 1024. - fog_start, 0.) * -fog_width);
}

void fragment() {
	vec3 color = texture(screen_texture, SCREEN_UV).rgb;
	float depth = sample_linear_depth_at(SCREEN_UV, INV_PROJECTION_MATRIX);
	
	vec2 screen_uv = SCREEN_UV;
	
	
	// OUTLINES
	float avg_depth;
	float outline_amount = compute_outline_amount(depth, screen_uv, INV_PROJECTION_MATRIX, avg_depth);
	//vec3 outline_color = vec3(1.);// / sqrt(color.r + color.g + color.b + 1.);

	color = mix(color, outline_color, outline_amount);
	
	 //FOG
	float fog_amount = clamp(compute_fog_amount(depth), 0, 1);
	color = mix(color, mix(sqrt(fog_color), fog_color * fog_color, fog_amount), fog_amount);
	
	ALBEDO = vec3(color);
}
