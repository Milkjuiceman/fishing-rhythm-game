shader_type spatial;
render_mode unshaded;
render_mode blend_add;

uniform sampler2D t;
uniform float scale;
uniform float strength;
uniform sampler2D depth_texture : hint_depth_texture;
uniform sampler2D color_texture : hint_screen_texture;
uniform float cutoff;

void vertex() {
	POSITION = vec4(UV*2.-1., 1., 1.);
}


void fragment() {
	float nonlinear_depth = texture(depth_texture, UV).r;
	// if not hitting anything, dont render
	if (nonlinear_depth == 0.) discard;
	// in foward+ depth is 0 to 1 while compatability is -1 to 1
	vec4 ndc = vec4(UV*2.-1., nonlinear_depth, 1.);
	vec4 view_pos = INV_PROJECTION_MATRIX * ndc;
	view_pos /= view_pos.w;
	// if >64 away, dont render
	if (-view_pos.z > 64.) discard;
	vec3 world_pos = (INV_VIEW_MATRIX * view_pos).xyz;
	vec2 uv = vec2(world_pos.x*0.8 + world_pos.y*0.7, world_pos.z) * scale;
	
	ALBEDO = texture(t, uv + vec2(0., TIME * 0.0334)).rgb;
	ALBEDO *= texture(t, uv.yx*0.786 + TIME*vec2(-0.0123, 0.0253) + vec2(0.783, 0.829)).rgb;
	ALBEDO *= texture(t, vec2(-uv.x, uv.y)*0.886 + TIME*vec2(0.021983, -0.0189) + vec2(0.239,0.263)).rgb;
	ALBEDO *= strength;
	ALBEDO *= mix(texture(color_texture, UV).rgb, vec3(0.5, 0.7, 0.9), 0.01);
	// fade out from 32 to 64 away
	ALBEDO *= clamp(2. + view_pos.z / 32., 0., 1.);
}