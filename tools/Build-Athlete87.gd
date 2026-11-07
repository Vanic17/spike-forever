extends SceneTree
## Offline authoring only. New anatomy and opaque swept fibers; no pose code.
const PSK=preload("res://src/psk.gd")
var random:=RandomNumberGenerator.new()
var body
var refinements
var stats: Dictionary={}
func _initialize():call_deferred("run")
func run():
	random.seed=87019
	body=PSK.new();assert(body.load_file("res://assets/active/body.psk"))
	# Share the audited subdivision implementation without running its build entry.
	refinements=preload("res://tools/Athlete87MeshRefinement.gd").new()
	var head=PSK.new();assert(head.load_file("res://assets/art/athlete87/source/Game/CharactersV1/01_Character_BodyParts/01_Heads/SK_Char_Head_Tier1_M_Perrin.psk",body.names))
	var face: ArrayMesh=open_lids(refinements.refine(head.mesh,"head"))
	var skin_only:=ArrayMesh.new();skin_only.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,face.surface_get_arrays(0))
	save("head",skin_only)
	var lashes:=ArrayMesh.new();lashes.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,face.surface_get_arrays(2));save("lashes",lashes)
	var eyes=PSK.new();assert(eyes.load_file("res://assets/active/eyes.psk",body.names))
	var ocular: ArrayMesh=refinements.refine(eyes.mesh,"eyes")
	var ocular_result:=ArrayMesh.new()
	for s in ocular.get_surface_count():
		var a=ocular.surface_get_arrays(s).duplicate(true);var points: PackedVector3Array=a[Mesh.ARRAY_VERTEX]
		for i in points.size():
			var origin:=Vector3(signf(points[i].x)*.034,1.776,.066)
			points[i]=origin+(points[i]-origin)+Vector3(0,-.0005,.001)
		a[Mesh.ARRAY_VERTEX]=points;rebuild(a,ocular_result)
	save("eyes",ocular_result)
	var footwear=PSK.new();assert(footwear.load_file("res://assets/art/athlete87/source/Game/CharactersV1/03_Character_Accessories/07_Shoes/SK_Char_Shoes_M_02.psk",body.names))
	save("shoes",footwear.mesh)
	var trunk: ArrayMesh=refinements.refine(body.mesh,"body")
	save("body",sculpt_hands(trunk))
	save("nails",fingernails(trunk))
	var cloth=PSK.new();assert(cloth.load_file("res://assets/active/cloth.psk",body.names))
	save("cloth",tailor(refinements.refine(cloth.mesh,"cloth")))
	save("hair",fibers(face,false))
	save("beard",fibers(face,true))
	FileAccess.open("res://docs/athlete87-build.json",FileAccess.WRITE).store_string(JSON.stringify({"seed":87019,"head_source":"SK_Char_Head_Tier1_M_Perrin, local licensed archive","method":"different anatomical head, refined hand skin and garment folds, individually swept opaque hair and beard fibers","parts":stats},"  "))
	print("ATHLETE87 BUILD PASS ",JSON.stringify(stats));quit()
func save(part: String,mesh: ArrayMesh):
	assert(ResourceSaver.save(mesh,"res://assets/art/athlete87/"+part+".res",ResourceSaver.FLAG_COMPRESS)==OK)
	var count:=0
	for s in mesh.get_surface_count():
		var index_count:=mesh.surface_get_array_index_len(s)
		count+=(index_count if index_count>0 else mesh.surface_get_array_len(s))/3
	stats[part]={"triangles":count,"surfaces":mesh.get_surface_count(),"bounds":str(mesh.get_aabb())}
func rebuild(a: Array,result: ArrayMesh):
	a[Mesh.ARRAY_TANGENT]=null
	var mesh:=ArrayMesh.new();mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,a)
	var st:=SurfaceTool.new();st.create_from(mesh,0);st.generate_normals();st.generate_tangents();st.commit(result)
func open_lids(mesh: ArrayMesh) -> ArrayMesh:
	var result:=ArrayMesh.new()
	for s in mesh.get_surface_count():
		var a=mesh.surface_get_arrays(s).duplicate(true);var v: PackedVector3Array=a[Mesh.ARRAY_VERTEX]
		for i in v.size():
			var p:=v[i];var dy:=p.y-1.776
			var falloff: float=exp(-pow(dy/.012,2))*exp(-pow((absf(p.x)-.034)/.023,4))*smoothstep(.066,.079,p.z)
			v[i].y+=.0026*tanh(dy/.0018)*falloff
			if s==0:
				# Anatomical sculpt in bind coordinates: cheek eminence, mandibular
				# angle, chin, nasal bridge and supraorbital arch. Not noise displacement.
				var cheek:=exp(-pow((absf(p.x)-.056)/.023,2)-pow((p.y-1.747)/.022,2)-pow((p.z-.070)/.045,2))
				var jaw:=exp(-pow((absf(p.x)-.063)/.026,2)-pow((p.y-1.668)/.022,2)-pow((p.z-.025)/.055,2))
				var chin:=exp(-pow(p.x/.030,2)-pow((p.y-1.647)/.016,2)-pow((p.z-.078)/.028,2))
				var nose:=exp(-pow(p.x/.013,2)-pow((p.y-1.758)/.027,2))*smoothstep(.07,.10,p.z)
				var brow:=exp(-pow((absf(p.x)-.035)/.030,2)-pow((p.y-1.798)/.011,2))*smoothstep(.04,.08,p.z)
				v[i].x+=signf(p.x)*(.0034*cheek+.0044*jaw)
				v[i].z+=.0018*cheek+.0040*chin+.0030*nose+.0020*brow
				v[i].y-=.0015*chin
		a[Mesh.ARRAY_VERTEX]=v;rebuild(a,result)
	return result
func sculpt_hands(source: ArrayMesh) -> ArrayMesh:
	var result:=ArrayMesh.new()
	for s in source.get_surface_count():
		var a=source.surface_get_arrays(s).duplicate(true)
		var v: PackedVector3Array=a[Mesh.ARRAY_VERTEX];var normals: PackedVector3Array=a[Mesh.ARRAY_NORMAL]
		var b: PackedInt32Array=a[Mesh.ARRAY_BONES];var w: PackedFloat32Array=a[Mesh.ARRAY_WEIGHTS]
		for i in v.size():
			var finger:=0.0;var knuckle:=0.0
			for k in 4:
				var name: String=body.names[b[i*4+k]]
				if "Hand" in name and name.right(1).is_valid_int():
					finger+=w[i*4+k]
					if name.ends_with("1") or name.ends_with("2"):knuckle+=w[i*4+k]
			# Shape the joint pads, webbing and extensor relief on the hand skin.
			if finger>.1:
				var relief: float=.0015*knuckle*maxf(0,normals[i].y)-.0004*finger*maxf(0,-normals[i].y)
				v[i]+=normals[i]*relief
				v[i].z+=sin(v[i].x*280.0)*.00035*knuckle
		a[Mesh.ARRAY_VERTEX]=v;rebuild(a,result)
	return result
func fingernails(source: ArrayMesh) -> ArrayMesh:
	var a=source.surface_get_arrays(0);var v: PackedVector3Array=a[Mesh.ARRAY_VERTEX];var bones: PackedInt32Array=a[Mesh.ARRAY_BONES];var weights: PackedFloat32Array=a[Mesh.ARRAY_WEIGHTS]
	var global_rest: Array[Transform3D]=[]
	for i in body.names.size():global_rest.append(body.rest[i] if i==0 or body.parents[i]<0 else global_rest[body.parents[i]]*body.rest[i])
	var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for bone in body.names.size():
		if not "Hand" in body.names[bone] or not body.names[bone].ends_with("3"):continue
		var points: Array[Vector3]=[]
		for i in v.size():
			for k in 4:
				if bones[i*4+k]==bone and weights[i*4+k]>.7:points.append(v[i]);break
		if points.is_empty():continue
		var direction: Vector3=(global_rest[bone].origin-global_rest[body.parents[bone]].origin).normalized()
		var dorsal: Vector3=(Vector3.UP-direction*direction.dot(Vector3.UP)).normalized()
		var side: Vector3=direction.cross(dorsal).normalized()
		var center:=Vector3.ZERO;var tip:=-INF;var surface:=-INF
		for point in points:center+=point;tip=maxf(tip,point.dot(direction));surface=maxf(surface,point.dot(dorsal))
		center/=points.size();center+=direction*(tip-center.dot(direction)-.0047)+dorsal*(surface-center.dot(dorsal)-.0003)
		var width: float=.0024 if "Pinky" in body.names[bone] else .0032
		for slice in 24:
			for point in [Vector2.ZERO,Vector2(cos(TAU*slice/24),sin(TAU*slice/24)),Vector2(cos(TAU*(slice+1)/24),sin(TAU*(slice+1)/24))]:
				st.set_normal(dorsal);st.set_uv((point+Vector2.ONE)*.5);st.set_bones(PackedInt32Array([bone,0,0,0]));st.set_weights(PackedFloat32Array([1,0,0,0]))
				st.add_vertex(center+side*point.x*width+direction*point.y*.0050+dorsal*(1-point.length_squared())*.0005)
	return st.commit()
func tailor(source: ArrayMesh) -> ArrayMesh:
	var result:=ArrayMesh.new()
	for s in source.get_surface_count():
		var a=source.surface_get_arrays(s).duplicate(true);var v: PackedVector3Array=a[Mesh.ARRAY_VERTEX];var n: PackedVector3Array=a[Mesh.ARRAY_NORMAL]
		for i in v.size():
			var p:=v[i]
			# Localized gathered folds around the waist, side panels and shorts.
			var waist:=exp(-pow((p.y-1.04)/.065,2))
			var sides:=smoothstep(.12,.28,absf(p.x))*exp(-pow((p.y-1.25)/.20,2))
			var shorts:=exp(-pow((p.y-.79)/.085,2))
			var fold: float=sin(p.y*118.0+absf(p.x)*27.0+p.z*17.0)*(.0024*waist+.0016*sides+.0018*shorts)
			v[i]+=n[i]*fold
		a[Mesh.ARRAY_VERTEX]=v;rebuild(a,result)
	return result
func fibers(face: ArrayMesh,beard: bool) -> ArrayMesh:
	var source=face.surface_get_arrays(0)
	var v: PackedVector3Array=source[Mesh.ARRAY_VERTEX];var normals: PackedVector3Array=source[Mesh.ARRAY_NORMAL];var indices: PackedInt32Array=source[Mesh.ARRAY_INDEX]
	var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var strands:=0
	for triangle in range(0,indices.size(),3):
		var ids=[indices[triangle],indices[triangle+1],indices[triangle+2]]
		var center: Vector3=(v[ids[0]]+v[ids[1]]+v[ids[2]])/3.0
		if not region(center,beard):continue
		var area: float=(v[ids[1]]-v[ids[0]]).cross(v[ids[2]]-v[ids[0]]).length()*.5
		var expected: float=area*(270000.0 if beard else 145000.0)
		var count:=int(expected)+(1 if random.randf()<fmod(expected,1.0) else 0)
		for strand in count:
			var u:=sqrt(random.randf());var t:=random.randf();var bary:=Vector3(1-u,u*(1-t),u*t)
			var p: Vector3=v[ids[0]]*bary.x+v[ids[1]]*bary.y+v[ids[2]]*bary.z
			if not region(p,beard):continue
			var n: Vector3=(normals[ids[0]]*bary.x+normals[ids[1]]*bary.y+normals[ids[2]]*bary.z).normalized()
			var top:=smoothstep(1.79,1.87,p.y)
			var length: float=random.randf_range(.003,.008) if beard else lerpf(.002,.025,top)*random.randf_range(.55,1.3)
			var flow:=Vector3(.30,-.18,-1.0) if not beard else Vector3(signf(p.x)*.1,-1,.15)
			flow=(flow-n*flow.dot(n)).normalized()
			var lift: float=.15 if beard else lerpf(.12,.27,top)
			var direction: Vector3=(flow+n*lift).normalized()
			var color:=Color("32251c").lerp(Color("705039"),random.randf()*.65)
			if beard:color=Color("38291f").lerp(Color("856348"),random.randf()*.45)
			var radius: float=random.randf_range(.00013,.00025) if beard else random.randf_range(.00017,.00034)
			strand_mesh(st,p+n*.00015,n,direction,length,radius,color,6)
			strands+=1
	# Close the scalp between roots with a fitted shell, not a detached hair cap.
	if not beard:
		for triangle in range(0,indices.size(),3):
			var ids=[indices[triangle],indices[triangle+1],indices[triangle+2]]
			var polygon: Array=[]
			for j in 3:
				var a: int=ids[j];var b: int=ids[(j+1)%3]
				var da:=hair_distance(v[a]);var db:=hair_distance(v[b])
				if da>=0:polygon.append([v[a],normals[a]])
				if (da>=0)!=(db>=0):
					var t: float=da/(da-db);polygon.append([v[a].lerp(v[b],t),normals[a].lerp(normals[b],t).normalized()])
			for j in range(1,polygon.size()-1):
				for vertex in [polygon[0],polygon[j],polygon[j+1]]:
					st.set_color(Color("3b291d"));st.set_normal(vertex[1]);st.set_uv(Vector2.ZERO)
					st.set_bones(PackedInt32Array([6,0,0,0]));st.set_weights(PackedFloat32Array([1,0,0,0]));st.add_vertex(vertex[0]+vertex[1]*.0005)
	st.index()
	var mesh:=st.commit();stats["beard_strands" if beard else "hair_strands"]=strands
	return mesh
func region(p: Vector3,beard: bool) -> bool:
	if beard:
		if p.z<.022 or p.y<1.623 or p.y>1.726:return false
		var mouth:=pow(p.x/.036,2)+pow((p.y-1.690)/.015,2)
		if mouth<1.0:return false
		if p.y>1.706 and absf(p.x)<.041:return p.y<1.718 and p.z>.09
		return absf(p.x)<.088 and p.z>.025
	return hair_distance(p)>0
func hair_distance(p: Vector3) -> float:
	var front:=smoothstep(-.015,.085,p.z)
	var hairline:=1.728+front*.119
	# Soft temple recession, not a rectangular hair cap.
	hairline+=.012*exp(-pow((absf(p.x)-.062)/.022,2))*front
	return minf(p.y-hairline,maxf(.083-absf(p.x),p.y-1.81))
func strand_mesh(st: SurfaceTool,p: Vector3,n: Vector3,flow: Vector3,length: float,radius: float,color: Color,bone: int):
	var side:=flow.cross(n).normalized()
	if side.length()<.5:side=Vector3.RIGHT
	var up:=side.cross(flow).normalized()
	for segment in 3:
		var a:=float(segment)/3;var b:=float(segment+1)/3
		var c0:=p+flow*length*a+n*sin(a*PI)*length*.15
		var c1:=p+flow*length*b+n*sin(b*PI)*length*.15
		for edge in 3:
			var r0: float=radius*(1-a*.85);var r1: float=radius*(1-b*.85)
			var q0: Vector3=side*cos(TAU*edge/3)+up*sin(TAU*edge/3)
			var q1: Vector3=side*cos(TAU*(edge+1)/3)+up*sin(TAU*(edge+1)/3)
			var positions=[c0+q0*r0,c1+q0*r1,c1+q1*r1,c0+q0*r0,c1+q1*r1,c0+q1*r0]
			for k in 6:
				st.set_color(color);st.set_normal(q0 if k in [0,1,3] else q1);st.set_uv(Vector2(float(edge)/3,a))
				st.set_bones(PackedInt32Array([bone,0,0,0]));st.set_weights(PackedFloat32Array([1,0,0,0]));st.add_vertex(positions[k])

