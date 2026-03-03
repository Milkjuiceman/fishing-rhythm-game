#[compute]
#version 450

layout(push_constant, std430) uniform Params {
	vec2 PIXEL_SIZE;
	ivec2 RASTER_SIZE;
};

layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

#include "inc/uniform_buffer.glsl"
layout(rgba16f, set = 1, binding = 0) uniform image2D WORKING_IMAGE;
layout(rgba16f, set = 2, binding = 0) uniform image2D COLOR_IMAGE;
layout(set = 3, binding = 0) uniform sampler2D FOG_IMAGE;


#include "inc/outline_sdf.glsl"


void main() {
	ivec2 uv = ivec2(gl_GlobalInvocationID.xy);
	if (uv.x >= RASTER_SIZE.x || uv.y >= RASTER_SIZE.y) return;
	vec2 uniform_uv = vec2(uv) * PIXEL_SIZE;

	vec4 img = imageLoad(COLOR_IMAGE, uv);
	vec4 values = imageLoad(WORKING_IMAGE, uv);
	vec2 fog = texture(FOG_IMAGE, uniform_uv).xy;

	// // if (values.a < 0.5) return;
	float sdf = outline_sdf(values.xyz, uniform_uv);
	// 1.5px fade off for anti aliasing
	// float strength = clamp((CONTROL_A - dis)*1., 0., 1.);
	float strength = clamp(sdf, 0., 1.);
	// if (strength <= 0.) return;

	imageStore(COLOR_IMAGE, uv, //values
		// mix(
			mix(
				img,
				vec4(0., 0., 0., 1.),
				sqrt(strength)
			// ),
			// mix(FOG_COLOR_A, FOG_COLOR_B, fog.y),
			// fog.x
		)
	);

	// float depth = abs(linearize_depth(values.z, INV_PROJECTION_MATRIX_2_3, INV_PROJECTION_MATRIX_3_3));
	// // float depth = INV_PROJECTION_MATRIX_2_3 / values.z + INV_PROJECTION_MATRIX_3_3;
	// depth = fract(depth * 0.01);
	// imageStore(COLOR_IMAGE, uv, vec4(mix(img.r, 0., sqrt(strength)), depth, values.z, img.a));

	// // For Debugging
	// vec3 color = (values.xyz * 0.9 + img.xyz * 0.1) / (0.1 / (img.xyz + 0.01) + 0.9);
	// imageStore(COLOR_IMAGE, uv, vec4(color, 1.));
}
