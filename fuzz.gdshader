shader_type canvas_item;

uniform float alpha;

float rounded(float x, float factor) {
	return round(x * factor) / factor;
}

float rand(float seed) {
	return cos(13.0 + seed * 17.0);
}

void fragment() {
	float t = floor(TIME * 8.0);
	vec3 color = vec3(1.0 - rand(t * rounded(UV.x, 18.0) * rounded(UV.y, 18.0) * 13.0), 1.0 - rand(t * rounded(UV.x, 18.0) * rounded(UV.y, 18.0) * 17.0), 1.0 - rand(t * UV.x * UV.y * 16.0)) * 0.5;
	COLOR = vec4(color, alpha);
}