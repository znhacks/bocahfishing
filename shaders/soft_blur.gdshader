shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float blur_amount : hint_range(0.0, 6.0) = 2.4;
uniform float dim_amount : hint_range(0.0, 1.0) = 0.06;

void fragment() {
    vec2 ps = SCREEN_PIXEL_SIZE * blur_amount;
    
    // 9-tap Gaussian distribution for smooth, high-performance bokeh blur
    vec4 col = vec4(0.0);
    col += texture(screen_texture, SCREEN_UV + vec2(-ps.x, -ps.y)) * 0.0625;
    col += texture(screen_texture, SCREEN_UV + vec2(0.0,   -ps.y)) * 0.125;
    col += texture(screen_texture, SCREEN_UV + vec2(ps.x,  -ps.y)) * 0.0625;
    col += texture(screen_texture, SCREEN_UV + vec2(-ps.x,  0.0))  * 0.125;
    col += texture(screen_texture, SCREEN_UV)                      * 0.25;
    col += texture(screen_texture, SCREEN_UV + vec2(ps.x,   0.0))  * 0.125;
    col += texture(screen_texture, SCREEN_UV + vec2(-ps.x,  ps.y)) * 0.0625;
    col += texture(screen_texture, SCREEN_UV + vec2(0.0,    ps.y)) * 0.125;
    col += texture(screen_texture, SCREEN_UV + vec2(ps.x,   ps.y)) * 0.0625;
    
    // Subtle darkening to increase contrast against foreground characters and UI
    col.rgb = mix(col.rgb, vec3(0.02, 0.04, 0.07), dim_amount);
    
    COLOR = col;
}
