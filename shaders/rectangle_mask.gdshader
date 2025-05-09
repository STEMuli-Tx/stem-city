shader_type canvas_item;
render_mode blend_mix;

uniform vec2 position;
uniform vec2 size;
uniform vec4 overlay_color = vec4(0, 0, 0, 0.6);

void fragment() {
	vec2 pixel_pos = FRAGCOORD.xy;
	bool in_rect = pixel_pos.x >= position.x && pixel_pos.x <= position.x + size.x &&
	               pixel_pos.y >= position.y && pixel_pos.y <= position.y + size.y;
	if (in_rect) {
		COLOR = vec4(0, 0.2, 0, 0.1); // Slightly green transparent for debug
	} else {
		COLOR = overlay_color; // Dark overlay elsewhere
	}
} 