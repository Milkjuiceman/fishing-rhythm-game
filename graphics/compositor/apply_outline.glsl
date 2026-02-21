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

	vec4 values = imageLoad(working_image, uv).xyzw;

	vec3 img = imageLoad(color_image, uv).rgb;

	float dark = values.w * 10. - 1.;

	vec3 color = mix(img, vec3(0.), clamp(vec3(dark*0.5, dark, dark*0.25), 0., 1.));

	// vec3 color = (values * 0.99 + img * 0.01) / (0.01 / (img + 0.001) + 0.99);

	imageStore(color_image, uv, vec4(color, 1.));
}
