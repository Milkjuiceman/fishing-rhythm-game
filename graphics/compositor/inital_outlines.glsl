#[compute]
#version 450

// Our push constant
layout(push_constant, std430) uniform Params {
	vec2 PIXEL_SIZE;
	ivec2 RASTER_SIZE;
};

// Invocations in the (x, y, z) dimension
layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(rgba16f, set = 0, binding = 0) uniform image2D WORKING_IMAGE;
layout(set = 1, binding = 0) uniform sampler2D DEPTH_TEXTURE;
layout(rgba16f, set = 2, binding = 0) uniform image2D NORM_ROUGH_IMAGE;

// Difference between push constant and uniform buffer:
// push constant is super fast and can hold 128B and only allowed one (per stage)
// uniform buffer is fast and can hold tens of kB and there can be <100
// storage buffer is slow and can hold many GB and allowed as much as you VRAM can handle

// Our uniform buffer uniform
layout(set = 3, binding=0) uniform SceneData {
	mat4 INV_PROJECTION_MATRIX;
	mat4 INV_VIEW_MATRIX;
};


// this needs to go after the uniforms
#include "linearize_depth.glsl"
#include "utils.glsl"

// The code we want to execute in each invocation
void main() {
	ivec2 uv = ivec2(gl_GlobalInvocationID.xy);
	if (uv.x >= RASTER_SIZE.x || uv.y >= RASTER_SIZE.y) return;

	vec4 result;

	if (uv.x >= RASTER_SIZE.x-1 || uv.y >= RASTER_SIZE.y-1 || uv.x<= 1 || uv.y <= 1) {
		result = vec4(0., 0., 0., 1.);
	} else {
		vec2 uniform_uv = vec2(uv) * PIXEL_SIZE;
		float nonlinear_depth;
		float depth = get_depth(uniform_uv, nonlinear_depth);

		// RASTER_SIZE.y because I find that the artifacts from the effect get worse with smaller resolutions
		// decreasing the outline sensitivity at smaller resolutions can make less outlines get detected - but its better than major artifacts 
		float DEPTH_SENSITIVITY = 0.4 * RASTER_SIZE.y * RASTER_SIZE.y;
		float NORMAL_SENSITIVITY = 15.;


		// WORLD SPACE EDGE DECTION
		vec3 position_11 = get_world_position(uniform_uv, nonlinear_depth);
		vec3 position_12 = get_world_position(uniform_uv+vec2(0,PIXEL_SIZE.y));
		vec3 position_10 = get_world_position(uniform_uv-vec2(0,PIXEL_SIZE.y));
		vec3 position_21 = get_world_position(uniform_uv+vec2(PIXEL_SIZE.x,0));
		vec3 position_01 = get_world_position(uniform_uv-vec2(PIXEL_SIZE.x,0));

		vec3 expected_centerX = (position_21 + position_01) / 2.;
		vec3 expected_centerY = (position_12 + position_10) / 2.;
		vec3 offsetX = position_11 - expected_centerX;
		vec3 offsetY = position_11 - expected_centerY;
		float offsetX_len_sq = dot(offsetX, offsetX);
		float offsetY_len_sq = dot(offsetY, offsetY);
		float depth_error = offsetX_len_sq + offsetY_len_sq;
		depth_error *= DEPTH_SENSITIVITY / depth;

		// NORMAL BASED EDGE DETECTION
		vec3 normal_11 = get_view_normal(uv);
		vec3 normal_12 = get_view_normal(uv+ivec2(0,1));
		vec3 normal_10 = get_view_normal(uv-ivec2(0,1));
		vec3 normal_21 = get_view_normal(uv+ivec2(1,0));
		vec3 normal_01 = get_view_normal(uv-ivec2(1,0));

		float normal_error = 0.;
		normal_error += 1.-abs(dot(normal_11,normal_12));
		normal_error += 1.-abs(dot(normal_11,normal_10));
		normal_error += 1.-abs(dot(normal_11,normal_21));
		normal_error += 1.-abs(dot(normal_11,normal_01));
		normal_error *= NORMAL_SENSITIVITY;

		// COMBINE EDGE DETECTIONS
		float hit_a = depth_error > 1. ? 0.85 : 0.;
		float hit_b = normal_error > 1. ? 0.85 : 0.;
		float combined_error = depth_error + normal_error + hit_a + hit_b;

		// SAVE RESULT
		result = combined_error > 1. ? vec4(uniform_uv, nonlinear_depth, 1.) : vec4(0., 0., 0., 1.);

		// DEBUG

		// // single pixel
		// result = uv == ivec2(700, 700) ? vec4(uniform_uv, 0.0591, 1.) : vec4(0., 0., 0., 1.);

		// // different modes
		// float hit = combined_error > 1. ? 1. : 0.;
		// float hit_deminished = hit * 0.5 + 0.5;
		// imageStore(WORKING_IMAGE, uv, vec4(
		// 	hit_a * 0.75 * hit_deminished,
		// 	hit,
		// 	hit_b * hit_deminished,
		// 0.));
	}

	imageStore(WORKING_IMAGE, uv, result);
}

