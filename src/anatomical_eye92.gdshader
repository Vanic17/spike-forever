shader_type spatial;
void fragment(){
	vec2 p=(UV-vec2(.5))*2.0;
	float r=length(p),a=atan(p.y,p.x);
	float iris=1.0-smoothstep(.45,.48,r);
	float fibres=.5+.5*sin(a*133.0+sin(a*29.0)*2.0+r*52.0);
	vec3 brown=mix(vec3(.032,.016,.007),vec3(.15,.078,.025),fibres*.6);
	brown*=mix(.42,1.0,smoothstep(.32,.39,r));
	float pupil=1.0-smoothstep(.19,.21,r);
	ALBEDO=mix(vec3(.43,.40,.36),mix(brown,vec3(.003),pupil),iris);
	ROUGHNESS=.17;SPECULAR=.48;
}
