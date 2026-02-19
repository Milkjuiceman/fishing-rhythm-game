#[compute]
#version 450

// Invocations in the (x, y, z) dimension
layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(rgba16f, set = 0, binding = 0) uniform image2D working_image;
layout(rgba16f, set = 1, binding = 0) uniform image2D color_image;

// Our push constant
layout(push_constant, std430) uniform Params {
	vec2 raster_size;
	vec2 pixel_size;
} params;

// The code we want to execute in each invocation
void main() {
	ivec2 uv = ivec2(gl_GlobalInvocationID.xy);
	ivec2 size = ivec2(params.raster_size);

	if (uv.x >= size.x || uv.y >= size.y) {
		return;
	}

	vec3 values = imageLoad(working_image, uv).xyz;

	vec3 img = imageLoad(color_image, uv).rgb;


	vec3 color = (values * 0.9 + img * 0.1) / (0.1 / (img + 0.01) + 0.9);

	imageStore(color_image, uv, vec4(color, 1.));
}
