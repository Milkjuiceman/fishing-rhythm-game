float linearize_depth(float nonlinear_depth, float inv_proj_mat_2_3, float inv_proj_mat_3_3) {
	float linear_depth = (nonlinear_depth == 0. ? 10000000000. : inv_proj_mat_2_3 / nonlinear_depth) + inv_proj_mat_3_3;
	return linear_depth;
}
