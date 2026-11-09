shader_type spatial;
render_mode cull_disabled;
uniform vec4 hit0=vec4(0.0,2.0,0.0,10.0);
uniform vec4 hit1=vec4(0.0,2.0,0.0,10.0);
uniform vec4 hit2=vec4(0.0,2.0,0.0,10.0);
uniform vec4 hit3=vec4(0.0,2.0,0.0,10.0);
uniform float visual_detail=2.0;
uniform bool geometry_cords=false;
float deformation(vec2 p,vec4 hit){
 float d=length((p-hit.xy)*vec2(.8,1.4));
 return hit.z*(1.0-exp(-hit.w*60.0))*exp(-hit.w*4.2)*exp(-d*d*2.0)*sin(hit.w*19.0-d*2.2+.8);
}
void vertex(){
 vec3 w=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
 float pin=pow(clamp(1.0-abs(w.x)/4.75,0.0,1.0),.35)*(.18+.82*sin(UV.y*3.14159265));
 float wave=deformation(w.xy,hit0)+deformation(w.xy,hit1)+deformation(w.xy,hit2)+deformation(w.xy,hit3);
 VERTEX+=(inverse(MODEL_MATRIX)*vec4(0.0,0.0,clamp(wave,-.42,.42)*pin,0.0)).xyz;
}
void fragment(){
 // Ninety-five by ten cells at ten centimetres each, in world metre scale.
 vec2 grid=UV*vec2(95.0,10.0);
 vec2 d=min(fract(grid),1.0-fract(grid));vec2 aa=max(fwidth(grid)*.55,vec2(.001));
 vec2 cord=1.0-smoothstep(vec2(.013)-aa,vec2(.013)+aa,d);
 float band=max(1.0-smoothstep(.069,.071,UV.y),smoothstep(.949,.951,UV.y));
 float weave=sin(UV.x*5700.0)*sin(UV.y*650.0);
 float fine=(1.0-smoothstep(.6,1.7,length(fwidth(UV*vec2(5700.0,650.0)))))*step(.5,visual_detail);
 ALBEDO=mix(vec3(.020,.024,.029),vec3(.88,.87,.84)*(1.0+weave*.025*fine),band);
 ALPHA=max(geometry_cords ? 0.0 : max(cord.x,cord.y),band);ALPHA_SCISSOR_THRESHOLD=.35;
 NORMAL_MAP=vec3(.5+sin(grid.x*6.283185)*.12*(1.0-band),.5+sin(grid.y*6.283185)*.12*(1.0-band),1.0);
 NORMAL_MAP_DEPTH=.45*step(.5,visual_detail);ROUGHNESS=mix(.76,.88,band);SPECULAR=.19;
}
