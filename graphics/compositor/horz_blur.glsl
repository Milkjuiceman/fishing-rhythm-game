#[compute]
#version 450

// Invocations in the (x, y, z) dimension
layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(rgba16f, set = 0, binding = 0) uniform image2D color_image;

// Our push constant
layout(push_constant, std430) uniform Params {
	vec2 raster_size;
	vec2 reserved;
} params;

// The code we want to execute in each invocation
void main() {
	ivec2 uv = ivec2(gl_GlobalInvocationID.xy);
	ivec2 size = ivec2(params.raster_size);

	if (uv.x >= size.x || uv.y >= size.y) {
		return;
	}

	vec4 color = imageLoad(color_image, uv)*6.;
    color += imageLoad(color_image, uv+ivec2(0,3))*5.;
    color += imageLoad(color_image, uv+ivec2(0,-3))*5.;
    color += imageLoad(color_image, uv+ivec2(0,10))*4.;
    color += imageLoad(color_image, uv+ivec2(0,-10))*4.;
    color += imageLoad(color_image, uv+ivec2(0,21))*2.;
    color += imageLoad(color_image, uv+ivec2(0,-21))*2.;
    color += imageLoad(color_image, uv+ivec2(0,36))*2.;
    color += imageLoad(color_image, uv+ivec2(0,-36))*2.;
    color /= 32.;

	imageStore(color_image, uv, color);
}

