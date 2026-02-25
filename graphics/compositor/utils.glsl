// returns the position in camera space
vec3 get_world_position(vec2 uniform_uv, float nonlinear_depth) {
	// in foward+ depth is 0 to 1 while compatability is -1 to 1 (this took 6 hours of debuging to figure out)
	vec4 ndc = vec4(uniform_uv*2.-1., nonlinear_depth, 1.);
	vec4 view = INV_PROJECTION_MATRIX * ndc;
	view /= view.w;
	return (INV_VIEW_MATRIX * view).xyz;
}

// override
vec3 get_world_position(vec2 uniform_uv) {
	float nonlinear_depth = texture(DEPTH_TEXTURE, uniform_uv).x;
	return get_world_position(uniform_uv, nonlinear_depth); 
}

float get_depth(vec2 uniform_uv, out float nonlinear_depth) {
	nonlinear_depth = texture(DEPTH_TEXTURE, uniform_uv).x;
	return linearize_depth(nonlinear_depth, INV_PROJECTION_MATRIX[2][3], INV_PROJECTION_MATRIX[3][3]);
}

// override
float get_depth(vec2 uniform_uv) {
	float nonlinear_depth;
	return get_depth(uniform_uv, nonlinear_depth);
}

vec3 get_view_normal(ivec2 uv) {
	vec4 rough_norm_compress = imageLoad(NORM_ROUGH_IMAGE, uv);
	vec3 view_normal = rough_norm_compress.xyz * 2.0 - 1.0;
	return normalize(view_normal);
}

// dont need to normalized again - at least visually looks identical
vec3 get_world_normal(ivec2 uv) {
	vec3 world_normal = mat3(INV_VIEW_MATRIX) * get_view_normal(uv);
	return world_normal;
}
