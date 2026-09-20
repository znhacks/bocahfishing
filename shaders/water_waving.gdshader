shader_type canvas_item;

uniform float wave_speed : hint_range(0.1, 5.0) = 1.0;
uniform float wave_freq : hint_range(1.0, 30.0) = 12.0;
uniform float wave_amp : hint_range(0.0005, 0.03) = 0.004;

void fragment() {
	vec2 uv = UV;
	
	// Perspective weighting: larger distortion near bottom, subtler near horizon
	float depth_weight = smoothstep(0.2, 0.95, uv.y);
	float cur_amp = wave_amp * (0.35 + 0.65 * depth_weight);
	
	// Fluid wave interference
	float w1 = sin(uv.y * wave_freq + TIME * wave_speed);
	float w2 = cos(uv.x * (wave_freq * 0.8) + uv.y * (wave_freq * 0.4) - TIME * (wave_speed * 0.85));
	
	float offset_x = (w1 * 0.65 + w2 * 0.35) * cur_amp;
	float offset_y = (w2 * 0.7 - w1 * 0.3) * (cur_amp * 0.5);
	
	vec2 distorted_uv = clamp(uv + vec2(offset_x, offset_y), vec2(0.001), vec2(0.999));
	vec4 col = texture(TEXTURE, distorted_uv);
	
	// Gentle ambient water reflection shimmer
	float glint = sin((uv.x * 18.0 + uv.y * 14.0) + TIME * (wave_speed * 1.5)) * 0.025 * depth_weight;
	col.rgb += vec3(glint);
	
	COLOR = col;
}
