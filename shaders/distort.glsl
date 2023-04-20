vec2 DistortPosition(in vec2 position){
    float CenterDistance = length(position);
    float DistortionFactor = mix(1.0, CenterDistance, 0.9);
    return position / DistortionFactor;
}