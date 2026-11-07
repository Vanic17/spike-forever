shader_type spatial;
uniform sampler2D iris : source_color, filter_linear_mipmap_anisotropic;
void fragment(){
	vec2 eye_uv=(UV-vec2(.5))*1.9+vec2(.5);
	float radius=length(eye_uv-vec2(.5));
	float iris_mask=1.0-smoothstep(.465,.495,radius);
	ALBEDO=mix(vec3(.78,.74,.69),texture(iris,clamp(eye_uv,vec2(.01),vec2(.99))).rgb,iris_mask);
	ROUGHNESS=.16;SPECULAR=.45;
}
