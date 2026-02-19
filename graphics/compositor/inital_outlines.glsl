#[compute]
#version 450

// Invocations in the (x, y, z) dimension
layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(rgba16f, set = 0, binding = 0) uniform image2D working_image;
layout(set = 1, binding = 0) uniform sampler2D depth_texture;
layout(rgba16f, set = 2, binding = 0) uniform image2D norm_rough_image;

// Our push constant
layout(push_constant, std430) uniform Params {
	vec2 raster_size;
	vec2 pixel_size;
// } params;


// layout(push_constant, std430) uniform ParamsB {
	mat4 INV_PROJECTION_MATRIX;
	vec3 INV_VIEW_X;
	vec3 INV_VIEW_Y;
	vec3 INV_VIEW_Z;
	vec3 INV_VIEW_W;
} params;

// float get_depth_at(vec2 uv) {
//     float depth_compress = texture(depth_texture, uv).x;
// 	float depth = (depth_compress == 0. ? 10000000000. : params.inv_proj_mat_2_3 / depth_compress) + params.inv_proj_mat_3_3;
//     return depth;
// }




vec3 get_world_position(vec2 uv) {
	float depth_compress = texture(depth_texture, uv).x;
	vec3 ndc = vec3((uv * 2.0) - 1.0, depth_compress*2.-1.);
	vec4 view = params.INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	view.xyz /= view.w;
	vec3 cast_position = normalize(
		params.INV_VIEW_X * view.x +
		params.INV_VIEW_Y * view.y +
		params.INV_VIEW_Z * view.z +
		params.INV_VIEW_W
	); // + params.INV_VIEW_OFFSET
	return cast_position;
}

// The code we want to execute in each invocation
void main() {
	ivec2 uv = ivec2(gl_GlobalInvocationID.xy);
	ivec2 size = ivec2(params.raster_size);

	if (uv.x >= size.x || uv.y >= size.y) {
		return;
	}

	vec2 uniform_uv = vec2(uv) * params.pixel_size;
	vec3 world_position = get_world_position(uniform_uv);

	world_position /= 10.;
	world_position += 0.5;
	world_position = clamp(world_position, vec3(0.), vec3(1.));

	// float center_depth = get_depth_at(uniform_uv);
	// float error = 0.;
	// error += abs(center_depth - get_depth_at(uniform_uv+vec2(params.pixel_size.x, 0)));
	// error += abs(center_depth - get_depth_at(uniform_uv-vec2(params.pixel_size.x, 0)));
	// error += abs(center_depth - get_depth_at(uniform_uv+vec2(0, params.pixel_size.x)));
	// error += abs(center_depth - get_depth_at(uniform_uv-vec2(0, params.pixel_size.x)));
	// vec3 result = (error > 4.) ? uniform_uv : vec2(0.,0.);

	imageStore(working_image, uv, vec4(world_position, 0.));
}
