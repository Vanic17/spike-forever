shader_type spatial;
render_mode cull_disabled;
uniform sampler2D fabric : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
uniform sampler2D fabric_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_disable;
uniform sampler2D identity : source_color, filter_linear, repeat_disable;
uniform vec4 ink : source_color = vec4(1.0);
void fragment() {
	vec3 cloth = texture(fabric, UV).rgb;
	vec4 print_pixel = texture(identity, clamp(UV2, vec2(0.0), vec2(1.0)));
	float in_print = step(0.0,UV2.x)*step(UV2.x,1.0)*step(0.0,UV2.y)*step(UV2.y,1.0);
	ALBEDO = mix(cloth, ink.rgb, print_pixel.a*in_print);
	ROUGHNESS = 0.86;
	NORMAL_MAP = texture(fabric_normal,UV).rgb;
	NORMAL_MAP_DEPTH = 0.45;
}
