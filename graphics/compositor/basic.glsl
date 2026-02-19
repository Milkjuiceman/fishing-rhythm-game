#[compute]
#version 450

// Invocations in the (x, y, z) dimension
layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(rgba16f, set = 0, binding = 0) uniform image2D color_image;
layout(set = 1, binding = 0) uniform sampler2D depth_texture;
layout(rgba16f, set = 2, binding = 0) uniform image2D norm_rough_image;

// Our push constant
layout(push_constant, std430) uniform Params {
	vec2 raster_size;
	vec2 pixel_size;
	float inv_proj_mat_2_3;
	float inv_proj_mat_3_3;
	vec2 reserved;
} params;

// The code we want to execute in each invocation
void main() {
	ivec2 uv = ivec2(gl_GlobalInvocationID.xy);
	ivec2 size = ivec2(params.raster_size);

	if (uv.x >= size.x || uv.y >= size.y) {
		return;
	}

	vec4 color = imageLoad(color_image, uv);

	vec4 rough_norm_compress = imageLoad(norm_rough_image, uv);
	vec3 normal_screen_space = normalize(rough_norm_compress.xyz * 2.0 - 1.0);
	float roughness = (rough_norm_compress.w > 0.5 ? 1. - rough_norm_compress.w : rough_norm_compress.w) * (255./127.);

	vec2 depth_uv = vec2(uv) * params.pixel_size;
	float depth_compress = texture(depth_texture, depth_uv).x;
	float depth = (depth_compress == 0. ? 10000000000. : params.inv_proj_mat_2_3 / depth_compress) + params.inv_proj_mat_3_3;

	// important part
	color.g = (color.r + color.b + color.b) / 3.;
	color.b = abs(fract(depth * 0.1) - 0.5) * 2.;
	color.r = 1. - normal_screen_space.z;
	// important part

	imageStore(color_image, uv, color);
}

