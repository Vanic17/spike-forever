shader_type spatial;
// Same authored eyeballs and brown iris identity; finer radial corneal detail.
void fragment(){
	vec2 p=(UV-vec2(.5))*2.0;
	float r=length(p),a=atan(p.y,p.x);
	float iris=1.0-smoothstep(.43,.47,r);
	float fibres=.5+.5*sin(a*133.0+sin(a*29.0)*2.0+r*52.0);
	vec3 brown=mix(vec3(.13,.071,.028),vec3(.33,.21,.09),fibres*.62);
	brown*=mix(.38,1.0,smoothstep(.31,.38,r));
	float pupil=1.0-smoothstep(.17,.19,r);
	vec3 sclera=vec3(.76,.73,.68);
	ALBEDO=mix(sclera,mix(brown,vec3(.006),pupil),iris);
	ROUGHNESS=.20;SPECULAR=.47;
}
