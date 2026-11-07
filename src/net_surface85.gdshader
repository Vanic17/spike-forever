shader_type spatial;
render_mode cull_disabled;
uniform float elapsed=10.0;
uniform float amplitude=0.0;
uniform vec2 impact=vec2(0.0,2.0);
void vertex(){ vec3 w=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz; float d=length((w.xy-impact)*vec2(0.75,1.5)); float pin=clamp((5.2-abs(w.x))*2.0,0.0,1.0); float wave=amplitude*exp(-elapsed*5.0)*exp(-d*d*1.3)*sin(elapsed*23.0-d*3.0)*pin; VERTEX+=(inverse(MODEL_MATRIX)*vec4(0.0,0.0,wave,0.0)).xyz; }
void fragment(){
	vec2 grid=UV*vec2(85.0,12.0);
	vec2 distance_to_thread=min(fract(grid),1.0-fract(grid));
	vec2 width=max(fwidth(grid),vec2(0.001));
	vec2 cord=1.0-smoothstep(vec2(.026)-width*.35,vec2(.026)+width*.35,distance_to_thread);
	float line=max(cord.x,cord.y);
	float tape=1.0-smoothstep(.042,.047,UV.y);
	float weave=sin(UV.x*3200.0)*sin(UV.y*320.0);
	float detail=1.0-smoothstep(.7,2.0,length(fwidth(UV*vec2(3200.0,320.0))));
	ALBEDO=mix(vec3(.038,.048,.060),vec3(.89,.88,.85)*(1.0+weave*.015*detail),tape);
	ALPHA=max(line,tape);ALPHA_SCISSOR_THRESHOLD=.42;
	ROUGHNESS=.86;SPECULAR=.18;
}
