#[compute]
#version 450

// Invocations in the (x, y, z) dimension
layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(rgba16f, set = 0, binding = 0) uniform image2D WORKING_IMAGE;
layout(set = 1, binding = 0) uniform sampler2D DEPTH_TEXTURE;
layout(rgba16f, set = 2, binding = 0) uniform image2D NORM_ROUGH_IMAGE;

// Our push constant
layout(push_constant, std430) uniform Params {
	vec2 RASTER_SIZE;
	vec2 PIXEL_SIZE;
};

// you may ask yourself:
// what the fuck is the difference between a push constant and a uniform buffer?
// i asked my self this very same question
// here is a good reddit post describing the difference:
// https://www.reddit.com/r/vulkan/comments/hssxcc/comment/fycgsur/
// But you are still asking:
// why did you choose to put this information in the uniform buffer and the other in the push constant
// this anouther question i asked myself
// but this time i decided i did not care enough to answer
// so fucking deal with it 
layout(set= 3, binding=0) uniform SceneData {
    mat4 INV_PROJECTION_MATRIX;
	mat4 INV_VIEW_MATRIX;
	float CONTROL;
};
// float get_depth_at(vec2 uv) {
//     float depth_compress = texture(DEPTH_TEXTURE, uv).x;
// 	float depth = (depth_compress == 0. ? 10000000000. : inv_proj_mat_2_3 / depth_compress) + inv_proj_mat_3_3;
//     return depth;
// }


// this function took >6 hours of trial and error of different things to get to work
// returns the position in camera space
vec3 get_world_position(vec2 uv) {
	float depth = texture(DEPTH_TEXTURE, uv).x;
	// in foward+ depth is 0 to 1 while compatability is -1 to 1
	vec4 ndc = vec4(uv*2.-1., depth, 1.);
	vec4 view = INV_PROJECTION_MATRIX * ndc;
	view /= view.w;
	return (INV_VIEW_MATRIX * view).xyz;
}

float linear_depth(vec2 uv) {
	float depth = texture(DEPTH_TEXTURE, uv).x;
	float linear_depth = (depth == 0. ? 10000000000. : -INV_PROJECTION_MATRIX[2][3] / depth) + -INV_PROJECTION_MATRIX[3][3];
	return linear_depth;
}

vec3 get_view_normal(ivec2 uv) {
	vec4 rough_norm_compress = imageLoad(NORM_ROUGH_IMAGE, uv);
	vec3 normal_screen_space = normalize(rough_norm_compress.xyz * 2.0 - 1.0);
	return normal_screen_space;
}

// float offset_at(vec3 normal_screen_space, vec3 view_position, vec2 uv) {
// 	vec3 sampled_loc = get_world_position(uv);
// 	// imagine a plane P with normal normal_screen_space and intersects view_position
// 	// this will return the distance that sampled_loc is from the plane
// 	// assuming that normal_screen_space is normalzied
// 	return dot(sampled_loc - view_position, normal_screen_space);
// }

// vec2 offset_at(vec3 normal_screen_space, vec3 view_position, vec2 uniform_uv, ivec2 uv) {
// 	vec3 sampled_norm = get_view_normal(uv);
// 	vec3 sampled_loc = get_world_position(uniform_uv);
// 	vec3 offset = sampled_loc - view_position;
// 	float normal_offset = 1. - abs(dot(normal_screen_space, sampled_norm));
// 	float depth_offset = abs(dot(offset, normal_screen_space));
// 	return vec2(depth_offset, normal_offset);
// }

vec2 offset_at(vec3 normal_screen_space, float depth, vec2 uniform_uv, ivec2 uv) {
	vec3 sampled_norm = get_view_normal(uv);
	float sampled_depth = linear_depth(uniform_uv);
	// vec3 sampled_loc = get_world_position(uniform_uv);
	// vec3 offset = sampled_loc - view_position;
	float normal_offset = 1. - abs(dot(normal_screen_space, sampled_norm));
	float depth_offset = abs(depth - sampled_depth);
	return vec2(depth_offset, normal_offset);
}


// The code we want to execute in each invocation
void main() {
	ivec2 uv = ivec2(gl_GlobalInvocationID.xy);
	ivec2 size = ivec2(RASTER_SIZE);

	if (uv.x >= size.x || uv.y >= size.y) {
		return;
	}

	vec2 uniform_uv = vec2(uv) * PIXEL_SIZE;
	vec3 view_position = get_world_position(uniform_uv);
	// float depth = linear_depth(uniform_uv);

	vec3 normal_screen_space = get_view_normal(uv);


	// vec2 error = vec2(0., 0.);
	// error += offset_at(normal_screen_space, view_position, uniform_uv+vec2(PIXEL_SIZE.x, 0), uv+ivec2(1,0));
	// error += offset_at(normal_screen_space, view_position, uniform_uv-vec2(PIXEL_SIZE.x, 0), uv-ivec2(1,0));
	// error += offset_at(normal_screen_space, view_position, uniform_uv+vec2(0, PIXEL_SIZE.x), uv+ivec2(0,1));
	// error += offset_at(normal_screen_space, view_position, uniform_uv-vec2(0, PIXEL_SIZE.x), uv-ivec2(0,1));


	// vec2 error = vec2(0., 0.);
	// error += offset_at(normal_screen_space, depth, uniform_uv+vec2(PIXEL_SIZE.x, 0), uv+ivec2(1,0));
	// error += offset_at(normal_screen_space, depth, uniform_uv-vec2(PIXEL_SIZE.x, 0), uv-ivec2(1,0));
	// error += offset_at(normal_screen_space, depth, uniform_uv+vec2(0, PIXEL_SIZE.x), uv+ivec2(0,1));
	// error += offset_at(normal_screen_space, depth, uniform_uv-vec2(0, PIXEL_SIZE.x), uv-ivec2(0,1));



	view_position *= 0.05;
	view_position = abs(fract(view_position));


	// imageStore(WORKING_IMAGE, uv, vec4(error.x / depth, error.y, 0., 0.));
	imageStore(WORKING_IMAGE, uv, vec4(view_position, 0.));
}
