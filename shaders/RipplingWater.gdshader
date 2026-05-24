shader_type spatial;

uniform vec3 color : source_color = vec3(0.1, 0.2, 0.3);
uniform float ripple_speed = 2.0;
uniform float ripple_frequency = 2.0;
uniform float ripple_width = 0.1;
uniform float ripple_size = 0.5;

varying float height;

void vertex() {
	// Pass local position to fragment shader
	// Distance from center using local XZ coordinates (ignore Y height)
	float dist = length(VERTEX.xz);
	// Create expanding ripples from actual geometric center
	float ripple = sin((dist * ripple_frequency * 10.0 - TIME * ripple_speed) * 6.28318);
	VERTEX.y += ripple * ripple_size;
	height = VERTEX.y;
}

void fragment() {
	float ripple = smoothstep(1.0 - ripple_width, 1.0, height);

	// Mix blue color with white ripples
	ALBEDO = mix(color, vec3(1.0), ripple * 0.5);
}

void light() {
	float lit = max(dot(NORMAL, LIGHT), 0.) * ATTENUATION;
	lit = lit > 0. ? (lit > 0.75 ? 1. : 0.5) : 0.;
	DIFFUSE_LIGHT += LIGHT_COLOR * lit / PI;
}