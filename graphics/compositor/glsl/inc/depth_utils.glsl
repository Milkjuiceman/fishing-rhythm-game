float linearize_depth(float nonlinear_depth) {
	float linear_depth = (nonlinear_depth == 0. ? 10000000000. : INV_PROJECTION_MATRIX[2][3] / nonlinear_depth) + INV_PROJECTION_MATRIX[3][3];
	return linear_depth;
}

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
	return linearize_depth(nonlinear_depth);
}

// override
float get_depth(vec2 uniform_uv) {
	float nonlinear_depth;
	return get_depth(uniform_uv, nonlinear_depth);
}
