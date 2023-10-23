shader_type spatial;

uniform float transparency : hint_range(0.0, 1.0) = 0.0;

void fragment() {
    vec3 color = vec3(0.0, 0.4, 1.0);
	ALBEDO = color;
	ALPHA = mix(0, 1, 1);
    if (transparency == 0.0f) {
		ALPHA = 0.0f;
    } else {
		ALPHA = transparency;
    }
}