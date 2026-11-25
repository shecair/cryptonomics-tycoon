shader_type canvas_item;

// Loading progress: 0.0 to 1.0
uniform float progress : hint_range(0.0, 1.0) = 1.0;

// Progress bar dimensions
uniform vec2 bar_size = vec2(886.0, 120.0);

// Rounded corners
uniform float corner_radius = 60.0;

// Edge smoothing
uniform float edge_softness = 1.5;


void fragment() {

    vec4 original_color = COLOR;

    vec2 pixel = UV * bar_size;

    float visible_width = bar_size.x * progress;

    float radius = min(
        corner_radius,
        min(visible_width * 0.5, bar_size.y * 0.5)
    );

    vec2 half_size = vec2(
        visible_width * 0.5,
        bar_size.y * 0.5
    );

    vec2 center = half_size;

    vec2 q = abs(pixel - center)
        - (half_size - vec2(radius));

    float distance_to_edge =
        length(max(q, vec2(0.0)))
        + min(max(q.x, q.y), 0.0)
        - radius;

    float mask = 1.0 - smoothstep(
        -edge_softness,
        edge_softness,
        distance_to_edge
    );

    if (progress <= 0.0) {
        mask = 0.0;
    }

    COLOR = vec4(
        original_color.rgb,
        original_color.a * mask
    );
}
