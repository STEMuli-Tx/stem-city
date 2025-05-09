shader_type canvas_item;
render_mode blend_mix;

uniform vec2 center;
uniform float radius = 100.0;
uniform vec4 overlay_color = vec4(0, 0, 0, 0.6);

void fragment() {
	float dist = distance(FRAGCOORD.xy, center);
	if (dist < radius) {
		COLOR = vec4(0.2, 0, 0, 0.1); // Slightly red transparent for debug
	} else {
		COLOR = overlay_color; // Dark overlay elsewhere
	}
} 