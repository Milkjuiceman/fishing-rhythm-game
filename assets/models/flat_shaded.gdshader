shader_type spatial;
uniform sampler2D text;

void fragment() {
	ALBEDO = texture(text, UV).xyz;
}

void light() {
    float lit = max(dot(NORMAL, LIGHT), 0.) * ATTENUATION;
    lit = lit > 0. ? (lit > 0.75 ? 1. : 0.5) : 0.;
    DIFFUSE_LIGHT += LIGHT_COLOR * lit / PI;
}
