shader_type spatial;
render_mode cull_back;
uniform sampler2D iris : source_color, filter_linear_mipmap_anisotropic,repeat_disable;
uniform sampler2D sclera : source_color, filter_linear_mipmap_anisotropic,repeat_disable;
void fragment(){
	vec2 centered=UV-vec2(.5);
	float radius=length(centered);
	float edge=max(fwidth(radius),.002);
	float iris_mask=1.0-smoothstep(.225-edge,.225+edge,radius);
	vec3 white=texture(sclera,UV).rgb;
	vec3 colored=texture(iris,clamp(centered/.45+vec2(.5),vec2(.0),vec2(1.0))).rgb;
	ALBEDO=mix(white,colored,iris_mask);
	ROUGHNESS=.16;SPECULAR=.5;
	CLEARCOAT=.4;
}
