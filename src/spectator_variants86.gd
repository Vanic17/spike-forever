extends RefCounted
## Same bodies, poses, instance count and LOD. No spectator collision changes.
static func apply(arena):
	if arena.crowd_materials.is_empty():return
	var shader:=Shader.new();var code: String=arena.crowd_materials[0].shader.code
	code=code.replace("uniform float clothing=0.0;","uniform float clothing=0.0;\nuniform float trousers86=0.0;")
	code=code.replace("step(0.54,person.w)*0.85","step(0.78,person.w)*0.72")
	code=code.replace("ALBEDO=mix(skin,shirt,clothing);","""
	vec3 denim=mix(vec3(.035,.055,.085),vec3(.20,.19,.17),person.z);
	float stripe=sin(head_height85*85.0);
	float stripe_weight=(1.0-step(.24,person.x))*.20*(1.0-smoothstep(.7,2.0,fwidth(head_height85)*85.0));
	shirt*=1.0+stripe*stripe_weight;
	shirt=mix(shirt,denim, trousers86);
	ALBEDO=mix(skin,shirt,clothing);
""")
	shader.code=code
	var legs=preload("res://src/source_assets.gd").texture("SK_CROWD_F__Legs01_C.png")
	for m in arena.crowd_materials:
		m.shader=shader;m.set_shader_parameter("trousers86",1.0 if m.get_shader_parameter("diffuse_map")==legs else 0.0)
	var palette: Array[Color]=[Color("718ba4"),Color("b7b5a8"),Color("456a74"),Color("9d7876"),Color("6a7d67"),Color("b3a277"),Color("777486"),Color("464c5d"),Color("a3afb5"),Color("c1bdb3"),Color("61847c"),Color("9b8a72"),Color("777f92"),Color("a4a9a2"),Color("736160"),Color("517089")]
	var serial:=0
	for node in arena.get_children():
		if not node is MultiMeshInstance3D or not node.has_meta("spectators"):continue
		var mm: MultiMesh=node.multimesh
		for i in mm.instance_count:
			var a: float=fposmod(sin(float(serial)*13.47+1.9)*7519.1,1.0)
			var b: float=fposmod(sin(float(serial)*29.13+7.1)*3413.7,1.0)
			var transform: Transform3D=mm.get_instance_transform(i)
			transform.basis=transform.basis.scaled(Vector3(.91+a*.17,.96+b*.08,.94+a*.10))
			mm.set_instance_transform(i,transform)
			mm.set_instance_color(i,palette[mini(palette.size()-1,int(a*palette.size()))])
			serial+=1
