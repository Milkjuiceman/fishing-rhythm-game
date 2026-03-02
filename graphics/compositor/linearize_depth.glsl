float linearize_depth(float nonlinear_depth) {
	float linear_depth = (nonlinear_depth == 0. ? 10000000000. : INV_PROJECTION_MATRIX[2][3] / nonlinear_depth) + INV_PROJECTION_MATRIX[3][3];
	return linear_depth;
}
