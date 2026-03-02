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
