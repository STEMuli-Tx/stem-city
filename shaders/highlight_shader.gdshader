shader_type canvas_item;

uniform vec2 highlight_position = vec2(0.0, 0.0);
uniform vec2 highlight_size = vec2(100.0, 50.0);
uniform float border_thickness = 3.0;
uniform vec4 highlight_color : source_color = vec4(0.376, 0.760, 0.658, 1.0);
uniform vec4 dimmer_color : source_color = vec4(0.0, 0.0, 0.0, 0.5);

void fragment() {
    // Convert screen coordinates to fragment coordinates
    vec2 screen_uv = SCREEN_UV;
    vec2 frag_pos = FRAGCOORD.xy;
    
    // Check if we're inside the highlight rectangle
    bool inside_rect = (frag_pos.x >= highlight_position.x && 
                       frag_pos.x <= highlight_position.x + highlight_size.x && 
                       frag_pos.y >= highlight_position.y && 
                       frag_pos.y <= highlight_position.y + highlight_size.y);
    
    // Check if we're in the border area
    bool on_border = (frag_pos.x >= highlight_position.x - border_thickness && 
                     frag_pos.x <= highlight_position.x + highlight_size.x + border_thickness && 
                     frag_pos.y >= highlight_position.y - border_thickness && 
                     frag_pos.y <= highlight_position.y + highlight_size.y + border_thickness) && !inside_rect;
    
    if (on_border) {
        // We're on the border, use the highlight color
        COLOR = highlight_color;
    } else if (inside_rect) {
        // We're inside the highlight, make it transparent
        COLOR = vec4(0.0, 0.0, 0.0, 0.0);
    } else {
        // We're outside, use the dimmer color
        COLOR = dimmer_color;
    }
}