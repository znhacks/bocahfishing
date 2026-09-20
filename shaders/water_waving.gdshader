shader_type canvas_item;

uniform float flow_speed : hint_range(0.01, 1.0) = 0.04;
uniform float wave_freq : hint_range(1.0, 30.0) = 12.0;
uniform float wave_amp : hint_range(0.0005, 0.02) = 0.0025;
uniform float trail_strength : hint_range(0.0, 1.0) = 0.4;

void fragment() {
	vec2 uv = UV;
	float depth = smoothstep(0.25, 0.95, uv.y);
	
	// Surface undulating ripples
	float w1 = sin(uv.y * wave_freq + TIME * 1.6);
	float w2 = cos(uv.x * wave_freq * 0.8 - TIME * 1.3);
	vec2 ripple = vec2(w1 * 0.65 + w2 * 0.35, w2 * 0.7 - w1 * 0.3) * (wave_amp * depth);
	
	// Continuous right-to-left flowing coordinate
	float flow_x = TIME * flow_speed;
	
	// Seamless ping-pong / mirrored UV scroll
	// As time progresses, content smoothly travels from right to left with 0 seams
	float cycle = fract((uv.x + flow_x) * 0.5);
	float scroll_x = 1.0 - abs(cycle * 2.0 - 1.0);
	
	vec2 flowing_uv = vec2(clamp(scroll_x + ripple.x, 0.001, 0.999), clamp(uv.y + ripple.y, 0.001, 0.999));
	vec4 col = texture(TEXTURE, flowing_uv);
	
	// Looping water current trails streaming right to left
	float stream_time = (uv.x + flow_x * 1.8);
	float tr1 = sin(stream_time * 26.0 + uv.y * 14.0);
	float tr2 = cos(stream_time * 19.0 - uv.y * 9.0 + sin(uv.y * 7.0));
	float trail_mask = smoothstep(0.68, 0.96, tr1 * 0.6 + tr2 * 0.4) * depth;
	
	// Ambient foam stream trails
	col.rgb += vec3(0.12, 0.22, 0.28) * trail_mask * trail_strength;
	
	// Moving sunlight / moonlight glint on ripples
	float glint = sin((stream_time * 22.0 + uv.y * 16.0) + TIME * 1.5) * 0.025 * depth;
	col.rgb += vec3(glint);
	
	COLOR = col;
}
