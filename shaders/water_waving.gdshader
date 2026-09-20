shader_type canvas_item;

uniform float flow_speed : hint_range(0.01, 0.5) = 0.04;
uniform float wave_speed : hint_range(0.1, 5.0) = 1.35;
uniform float wave_height : hint_range(0.005, 0.06) = 0.022;
uniform float wave_freq : hint_range(2.0, 30.0) = 8.5;
uniform float trail_strength : hint_range(0.0, 1.0) = 0.45;

void fragment() {
	vec2 uv = UV;
	
	// Perspective depth: waves swell much higher in foreground, gentler near horizon
	float depth = smoothstep(0.26, 0.96, uv.y);
	
	// Continuous right-to-left flowing coordinate
	float flow_x = TIME * flow_speed;
	float wave_time = TIME * wave_speed;
	
	// Mirrored seamless horizontal UV scroll (Right to Left)
	float cycle = fract((uv.x + flow_x) * 0.5);
	float scroll_x = 1.0 - abs(cycle * 2.0 - 1.0);
	
	// Dynamic multi-layer organic wave displacement (Efek Bergelombang Air)
	// 1. Primary rolling swell (ombak mengayun naik-turun)
	float sw1 = sin((scroll_x * wave_freq + uv.y * 4.0) + wave_time * 1.8);
	// 2. Secondary undulating ripple (riak air sekunder)
	float sw2 = cos((scroll_x * (wave_freq * 1.6) - uv.y * 7.5) + wave_time * 1.25);
	// 3. Fine fluid surface turbulence (tekstur cair dinamis)
	float sw3 = sin((scroll_x * (wave_freq * 3.0) + uv.y * 13.0) - wave_time * 1.1);
	
	// Combined undulating wave offset that distorts the actual image
	vec2 wave_distort;
	wave_distort.y = (sw1 * 0.65 + sw2 * 0.25 + sw3 * 0.10) * wave_height * depth;
	wave_distort.x = (sw2 * 0.55 - sw1 * 0.35 + sw3 * 0.10) * (wave_height * 0.6) * depth;
	
	vec2 distorted_uv = vec2(clamp(scroll_x + wave_distort.x, 0.001, 0.999), clamp(uv.y + wave_distort.y, 0.001, 0.999));
	vec4 col = texture(TEXTURE, distorted_uv);
	
	// Wave crest lighting: highlights appear on the peaks of the waves
	float crest = smoothstep(0.3, 0.9, sw1 * 0.6 + sw2 * 0.4) * depth;
	col.rgb += vec3(0.08, 0.16, 0.22) * crest;
	
	// Dynamic looping water current trails streaming right to left
	float stream_pos = uv.x + flow_x * 1.6;
	float tr1 = sin(stream_pos * 24.0 + uv.y * 12.0);
	float tr2 = cos(stream_pos * 16.0 - uv.y * 8.0 + sw1 * 1.5);
	float trail_mask = smoothstep(0.65, 0.96, tr1 * 0.6 + tr2 * 0.4) * depth;
	col.rgb += vec3(0.14, 0.24, 0.30) * trail_mask * trail_strength;
	
	// Specular sun / moon water glints dancing on the waves
	float glint = sin(((stream_pos * 20.0) + uv.y * 15.0) + wave_time * 1.5) * 0.03 * depth;
	col.rgb += vec3(glint);
	
	COLOR = col;
}
