#[compute]
#version 450

layout(push_constant, std430) uniform Params {
	vec2 PIXEL_SIZE;
	ivec2 RASTER_SIZE;
};

// Invocations in the (x, y, z) dimension
layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(rgba16f, set = 0, binding = 0) uniform image2D WORKING_IMAGE;
layout(rgba16f, set = 1, binding = 0) uniform image2D COLOR_IMAGE;


layout(set = 2, binding=0) uniform UniformBuffer{
	int JUMP_DISTANCE;
	float CONTROL_A;
};

// The code we want to execute in each invocation
void main() {
	ivec2 uv = ivec2(gl_GlobalInvocationID.xy);
	if (uv.x >= RASTER_SIZE.x || uv.y >= RASTER_SIZE.y) return;
	vec2 uniform_uv = vec2(uv) * PIXEL_SIZE;

	vec4 img = imageLoad(COLOR_IMAGE, uv);

	vec4 values = imageLoad(WORKING_IMAGE, uv).xyzw;


	if (values.a < 0.5) return;
	vec2 offset = values.xy - uniform_uv;
	float dis = length(offset * vec2(RASTER_SIZE));
	// 1.5px fade off for anti aliasing
	float strength = clamp((CONTROL_A - dis)*0.75, 0., 1.);
	if (strength <= 0.) return;
	imageStore(COLOR_IMAGE, uv, mix(img, vec4(0., 0., 0., 1.), strength));


	// For Debugging
	// vec3 color = (values.xyz * 0.9 + img * 0.1) / (0.1 / (img + 0.01) + 0.9);
	// imageStore(COLOR_IMAGE, uv, vec4(color, 1.));
}
