
float outline_sdf(vec3 value, vec2 uniform_uv) {
    float dis = length((value.xy - uniform_uv) * vec2(RASTER_SIZE));
    float width = value.z * float(RASTER_SIZE.y);
    return width - dis;
}


float outline_sdf_sq(vec3 value, vec2 uniform_uv) {
    vec2 a = (value.xy - uniform_uv) * vec2(RASTER_SIZE);
    float dis_sq = dot(a,a);
    float width = value.z * float(RASTER_SIZE.y);
    return width * width - dis_sq;
}
