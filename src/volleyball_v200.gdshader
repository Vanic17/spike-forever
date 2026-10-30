shader_type spatial;
render_mode specular_schlick_ggx;
uniform sampler2D markings : source_color, filter_linear_mipmap_anisotropic;
varying vec3 local_point;
void vertex(){local_point=VERTEX;}
void fragment(){
	vec3 n=normalize(local_point);
	vec3 a=abs(n);
	vec2 p;
	// Each of the six spherical faces carries three swept panels. Alternating
	// tangent axes gives the V200W pinwheel rather than latitude bands.
	if(a.x>=a.y && a.x>=a.z){p=vec2(n.z,n.y)/a.x; p.x*=sign(n.x);}
	else if(a.y>=a.z){p=vec2(n.x,n.z)/a.y; p.x*=sign(n.y);}
	else {p=vec2(n.y,n.x)/a.z; p.x*=sign(n.z);}
	float curve=p.y+0.28*sin(p.x*2.0)-0.17*p.x;
	float edge=abs(curve)-0.34;
	float aa=max(fwidth(edge),0.002);
	float blue=1.0-smoothstep(-aa,aa,edge);
	vec3 yellow=vec3(1.0,0.76,0.007);
	vec3 navy=vec3(0.014,0.047,0.30);
	vec3 color=mix(yellow,navy,blue);
	float seam=1.0-smoothstep(0.004,0.013+aa,abs(edge));
	float face_seam=1.0-smoothstep(0.975-aa,0.995,max(abs(p.x),abs(p.y)));
	color*=mix(0.68,1.0,face_seam)*(1.0-0.20*seam);
	// Small molded dimples disappear smoothly below a pixel to avoid shimmer.
	vec2 grid=p*145.0;
	float d=length(fract(grid)-0.5);
	float detail=1.0-smoothstep(0.5,1.5,max(length(dFdx(grid)),length(dFdy(grid))));
	float pore=(1.0-smoothstep(0.14,0.30,d))*detail;
	color*=1.0-0.09*pore;
	vec2 label_uv=vec2(p.x*0.90+0.5,(curve+0.22)*1.8);
	float inside=step(0.0,label_uv.x)*step(label_uv.x,1.0)*step(0.0,label_uv.y)*step(label_uv.y,1.0);
	float ink=texture(markings,clamp(label_uv,vec2(0.0),vec2(1.0))).a*inside*blue;
	ALBEDO=mix(color,vec3(0.96),ink);
	ROUGHNESS=0.57+0.10*pore;
	SPECULAR=0.32;
}
