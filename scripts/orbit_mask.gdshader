shader_type canvas_item;

void fragment() {
    vec4 ring_color = texture(TEXTURE, UV);

    if (UV.y < 0.5) {
        ring_color.a = 0.0;
    }

    COLOR = ring_color;
}
