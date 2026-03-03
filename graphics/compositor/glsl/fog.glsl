#[compute]
#version 450

// these are the size of the FOG_IMAGE (which may be different resolution that COLOR_IMAGE)
layout(push_constant, std430) uniform Params {
	vec2 PIXEL_SIZE;
	ivec2 RASTER_SIZE;
};

// Invocations in the (x, y, z) dimension
layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

#include "inc/uniform_buffer.glsl"
layout(set = 1, binding = 0) uniform sampler2D WORKING_TEXTURE;
layout(set = 2, binding = 0) uniform sampler2D DEPTH_TEXTURE;
layout(rg16f, set = 3, binding = 0) uniform image2D FOG_IMAGE;


#include "inc/linearize_depth.glsl"
#include "inc/depth_utils.glsl"
#include "inc/outline_sdf.glsl"


void main() {
	ivec2 uv = ivec2(gl_GlobalInvocationID.xy);
	if (uv.x >= RASTER_SIZE.x || uv.y >= RASTER_SIZE.y) return;
	vec2 uniform_uv = vec2(uv) * PIXEL_SIZE;

    vec4 values = texture(WORKING_TEXTURE, uniform_uv);

    float sdf = outline_sdf(values.xyz, uniform_uv);
    float strength = clamp(sdf*0.5, 0., 1.); // * 0.5 cause half resolution

    float depth = get_depth(uniform_uv);
    float outline_depth = linearize_depth(values.w);
    float used_depth = mix(depth, outline_depth, strength);

    float amount = 1. - exp(-used_depth * FOG_DENSITY);
	imageStore(FOG_IMAGE, uv, vec4(amount, uniform_uv.y, 0., 0.));
}
