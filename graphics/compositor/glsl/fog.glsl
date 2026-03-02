#[compute]
#version 450

layout(push_constant, std430) uniform Params {
	vec2 PIXEL_SIZE;
	ivec2 RASTER_SIZE;
};

// Invocations in the (x, y, z) dimension
layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

#include "inc/uniform_buffer.glsl"
layout(rg16f, set = 1, binding = 0) uniform image2D FOG_IMAGE;
layout(set = 2, binding = 0) uniform sampler2D DEPTH_TEXTURE;


#include "inc/depth_utils.glsl"


void main() {
	ivec2 uv = ivec2(gl_GlobalInvocationID.xy);
	if (uv.x >= RASTER_SIZE.x || uv.y >= RASTER_SIZE.y) return;
	vec2 uniform_uv = vec2(uv) * PIXEL_SIZE;

	imageStore(FOG_IMAGE, uv, vec4(0.));
}
