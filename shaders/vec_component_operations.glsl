float getVecAverage(vec3 v) {
    return (v.r + v.g + v.b) / 3;
}

float getVecSum(vec3 v) {
    return v.r + v.g + v.b;
}

vec3 scaleMaxTreshold(vec3 v, float treshold) {
    float maxValue = max(max(v.r, v.g), v.b);
    if(maxValue < treshold) return v;

    float scale = treshold / maxValue;
    return v * scale;
}