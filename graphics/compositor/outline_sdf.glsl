
float outline_sdf(vec3 value, vec2 uniform_uv) {
    float dis = length((value.xy - uniform_uv) * vec2(RASTER_SIZE));
    float depth = linearize_depth(value.z);
    return OUTLINE_THICKNESS / depth - dis;

    // return sqrt(outline_sdf_sq(value, uniform_uv));
}


float outline_sdf_sq(vec3 value, vec2 uniform_uv) {
    return outline_sdf(value, uniform_uv);
    
    // return abs(dot(offset, offset) * linearize_depth(value.z, INV_PROJECTION_MATRIX_2_3, INV_PROJECTION_MATRIX_3_3) * CONTROL_A);
    // return abs(dot(offset, offset));
}
