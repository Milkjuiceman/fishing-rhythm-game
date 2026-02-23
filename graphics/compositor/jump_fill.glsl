#[compute]
#version 450

layout(push_constant, std430) uniform PushConstant{
	vec2 PIXEL_SIZE;
	ivec2 RASTER_SIZE;
};

// Invocations in the (x, y, z) dimension
layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(rgba16f, set = 0, binding = 0) uniform image2D INPUT_IMAGE;
layout(rgba16f, set = 1, binding = 0) uniform image2D OUTPUT_IMAGE;

layout(set = 2, binding=0) uniform UniformBuffer{
	int JUMP_DISTANCE;
	float CONTROL_A;
};

void update_best(in out vec4 best, in out float best_dis_sq, vec2 uniform_uv, ivec2 sample_uv) {
	vec4 considered = imageLoad(INPUT_IMAGE, sample_uv);
	if (considered.a < 0.5) return;
	vec2 offset = considered.xy - uniform_uv;
	offset *= vec2(RASTER_SIZE);
	float dis_sq = abs(dot(offset, offset));
	if (dis_sq < best_dis_sq) {
		best_dis_sq = dis_sq;
		best = considered;
	}
}

void main() {
	ivec2 uv = ivec2(gl_GlobalInvocationID.xy);
	if (uv.x >= RASTER_SIZE.x || uv.y >= RASTER_SIZE.y) return;
	vec2 uniform_uv = vec2(uv) * PIXEL_SIZE;

	// imageStore(OUTPUT_IMAGE, uv, imageLoad(INPUT_IMAGE, uv));
	// return;

	vec4 best = vec4(0.);
	float best_dis_sq = 2000000000000000000000000.;
	update_best(best, best_dis_sq, uniform_uv, uv);
	update_best(best, best_dis_sq, uniform_uv, uv+ivec2(JUMP_DISTANCE,0));
	update_best(best, best_dis_sq, uniform_uv, uv-ivec2(JUMP_DISTANCE,0));
	update_best(best, best_dis_sq, uniform_uv, uv+ivec2(0,JUMP_DISTANCE));
	update_best(best, best_dis_sq, uniform_uv, uv-ivec2(0,JUMP_DISTANCE));
		

	// vec4 considered = imageLoad(INPUT_IMAGE, uv+ivec2(JUMP_DISTANCE,0));
	// best = best.z < considered.z ? best : considered;
	// considered = imageLoad(INPUT_IMAGE, uv-ivec2(JUMP_DISTANCE,0));
	// best = best.z < considered.z ? best : considered;
	// considered = imageLoad(INPUT_IMAGE, uv+ivec2(0,JUMP_DISTANCE));
	// best = best.z < considered.z ? best : considered;
	// considered = imageLoad(INPUT_IMAGE, uv-ivec2(0,JUMP_DISTANCE));
	// best = best.z < considered.z ? best : considered;

	imageStore(OUTPUT_IMAGE, uv, best);
}
