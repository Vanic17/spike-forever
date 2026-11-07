shader_type spatial;
varying vec3 world_position;
void vertex(){world_position=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment(){
	// Exact original cutaway: keep all occupied tiers and camera clearances.
	if(abs(world_position.x)<22.5 && abs(world_position.z)<28.0 && world_position.y<6.6)discard;
	float panel=min(fract(world_position.y*.33),fract((world_position.x+world_position.z)*.12));
	float joint=1.0-smoothstep(0.012,0.032,panel);
	float variation=sin(world_position.x*3.1+world_position.y*1.7)*sin(world_position.z*2.3)*.007;
	ALBEDO=vec3(.105,.128,.162)*(1.0-joint*.20)+variation;
	ROUGHNESS=.87;SPECULAR=.18;
}
