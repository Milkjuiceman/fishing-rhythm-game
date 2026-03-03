#[compute]
#version 450

layout(push_constant, std430) uniform PushConstant{
	vec2 PIXEL_SIZE;
	ivec2 RASTER_SIZE;
	int JUMP_DISTANCE_DIAG;
	int JUMP_DISTANCE_STRA;
};

layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

#include "inc/uniform_buffer.glsl"
layout(rgba16f, set = 1, binding = 0) uniform image2D INPUT_IMAGE;
layout(rgba16f, set = 2, binding = 0) uniform image2D OUTPUT_IMAGE;


#include "inc/outline_sdf.glsl"


void update_best(in out vec4 best, in out float best_dis_sq, vec2 uniform_uv, ivec2 sample_uv) {
	vec4 considered = imageLoad(INPUT_IMAGE, sample_uv);
	float dis_sq = outline_sdf_sq(considered.xyz, uniform_uv);
	if (dis_sq > best_dis_sq) {
		best_dis_sq = dis_sq;
		best = considered;
	}
}

void main() {
	ivec2 uv = ivec2(gl_GlobalInvocationID.xy);
	if (uv.x >= RASTER_SIZE.x || uv.y >= RASTER_SIZE.y) return;
	vec2 uniform_uv = vec2(uv) * PIXEL_SIZE;

	vec4 best = vec4(0.);
	float best_dis_sq = -2000000000000000000000000.;
	update_best(best, best_dis_sq, uniform_uv, uv);
	update_best(best, best_dis_sq, uniform_uv, uv+ivec2(JUMP_DISTANCE_DIAG,JUMP_DISTANCE_DIAG));
	update_best(best, best_dis_sq, uniform_uv, uv+ivec2(JUMP_DISTANCE_DIAG,-JUMP_DISTANCE_DIAG));
	update_best(best, best_dis_sq, uniform_uv, uv+ivec2(-JUMP_DISTANCE_DIAG,JUMP_DISTANCE_DIAG));
	update_best(best, best_dis_sq, uniform_uv, uv+ivec2(-JUMP_DISTANCE_DIAG,-JUMP_DISTANCE_DIAG));
	update_best(best, best_dis_sq, uniform_uv, uv+ivec2(JUMP_DISTANCE_STRA,0));
	update_best(best, best_dis_sq, uniform_uv, uv-ivec2(JUMP_DISTANCE_STRA,0));
	update_best(best, best_dis_sq, uniform_uv, uv+ivec2(0,JUMP_DISTANCE_STRA));
	update_best(best, best_dis_sq, uniform_uv, uv-ivec2(0,JUMP_DISTANCE_STRA));

	imageStore(OUTPUT_IMAGE, uv, best);
}
