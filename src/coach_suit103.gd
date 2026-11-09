extends RefCounted
## Skinned tailoring on the existing staff rig. Animation ownership stays unchanged.
static var meshes: Dictionary={}
static func material(color: Color,roughness: float=.85) -> StandardMaterial3D:
	var mat:=StandardMaterial3D.new();mat.albedo_color=color;mat.roughness=roughness
	mat.cull_mode=BaseMaterial3D.CULL_DISABLED
	return mat
static func vertex(st: SurfaceTool,v: Vector3,bones: PackedInt32Array,weights: PackedFloat32Array,uv: Vector2=Vector2.ZERO):
	st.set_bones(bones);st.set_weights(weights);st.set_uv(uv);st.add_vertex(v)
static func triangle(st: SurfaceTool,a: Vector3,b: Vector3,c: Vector3,bone: int):
	var ids:=PackedInt32Array([bone,0,0,0]);var weights:=PackedFloat32Array([1,0,0,0])
	for v in [a,b,c]:vertex(st,v,ids,weights)
static func tube(st: SurfaceTool,a: Vector3,b: Vector3,r0: float,r1: float,bone: int):
	var axis: Vector3=(b-a).normalized();var across:=axis.cross(Vector3.FORWARD).normalized()
	if across.length()<.1:across=Vector3.RIGHT
	var depth:=axis.cross(across).normalized()
	var ids:=PackedInt32Array([bone,0,0,0]);var weights:=PackedFloat32Array([1,0,0,0])
	for i in 20:
		var u:=TAU*i/20;var w:=TAU*(i+1)/20
		var va: Vector3=across*cos(u)+depth*sin(u);var vb: Vector3=across*cos(w)+depth*sin(w)
		for v in [a+va*r0,b+va*r1,b+vb*r1,a+va*r0,b+vb*r1,a+vb*r0]:vertex(st,v,ids,weights)
static func front(y: float) -> float:
	var ys: Array=[1.15,1.25,1.35,1.45,1.55,1.60]
	var zs: Array=[.1954,.178,.146,.1243,.079,.0474]
	for i in range(1,ys.size()):
		if y<=ys[i]:return lerpf(zs[i-1],zs[i],inverse_lerp(ys[i-1],ys[i],y))+.018
	return .0654
static func build(rig,team: int) -> ArrayMesh:
	var key:=str(team)
	if meshes.has(key):return meshes[key]
	var global_pose: Array[Transform3D]=[]
	for i in rig.names.size():global_pose.append(global_pose[rig.parents[i]]*rig.rest[i] if i>0 else rig.rest[i])
	var jacket:=SurfaceTool.new();var shirt:=SurfaceTool.new();var trousers:=SurfaceTool.new();var details:=SurfaceTool.new()
	for st in [jacket,shirt,trousers,details]:st.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Preserve the source body's fitted trouser and torso topology/weights.
	var a: Array=rig.mesh.surface_get_arrays(7)
	var indices: PackedInt32Array=a[Mesh.ARRAY_INDEX]
	var verts: PackedVector3Array=a[Mesh.ARRAY_VERTEX]
	for face in range(0,indices.size(),3):
		var mid: Vector3=(verts[indices[face]]+verts[indices[face+1]]+verts[indices[face+2]])/3
		# Replace short sleeve geometry entirely, avoiding a second sleeve cuff
		# halfway down the arm over the new full-length jacket sleeve.
		if mid.y>1.13 and mid.y<1.40 and absf(mid.x)>.22:continue
		var st: SurfaceTool=trousers if mid.y<1.03 else jacket
		for k in 3:
			var index: int=indices[face+k];var v: Vector3=verts[index]
			if st==jacket:v.x*=1.035;v.z*=1.045
			var ids:=PackedInt32Array();var weights:=PackedFloat32Array()
			for j in 4:ids.append(a[Mesh.ARRAY_BONES][index*4+j]);weights.append(a[Mesh.ARRAY_WEIGHTS][index*4+j])
			vertex(st,v,ids,weights,a[Mesh.ARRAY_TEX_UV][index])
	for side in ["Left","Right"]:
		var upper: int=rig.names.find(side+"Arm");var lower: int=rig.names.find(side+"ForeArm");var hand: int=rig.names.find(side+"Hand")
		var shoulder: Vector3=global_pose[upper].origin;var elbow: Vector3=global_pose[lower].origin;var wrist: Vector3=global_pose[hand].origin
		tube(jacket,shoulder,elbow,.108,.078,upper)
		tube(jacket,elbow,wrist.lerp(elbow,.07),.073,.054,lower)
		tube(shirt,wrist.lerp(elbow,.085),wrist.lerp(elbow,.015),.055,.052,lower)
	var chest: int=rig.names.find("Spine2")
	if chest<0:chest=rig.names.find("Spine")
	# A continuous shirt inset follows the actual chest profile. Do not classify
	# whole source triangles as white: that creates jagged boundaries.
	for i in 12:
		var ya:=lerpf(1.20,1.60,float(i)/12);var yb:=lerpf(1.20,1.60,float(i+1)/12)
		var wa:=lerpf(.03,.074,float(i)/12);var wb:=lerpf(.03,.074,float(i+1)/12)
		var a0:=Vector3(-wa,ya,front(ya));var a1:=Vector3(wa,ya,front(ya));var b0:=Vector3(-wb,yb,front(yb));var b1:=Vector3(wb,yb,front(yb))
		triangle(shirt,a0,b0,b1,chest);triangle(shirt,a0,b1,a1,chest)
	# Raised lapels and folded shirt collar use the same fitted profile.
	for sign_x in [-1,1]:
		triangle(details,Vector3(sign_x*.075,1.58,front(1.58)+.004),Vector3(sign_x*.145,1.44,front(1.44)+.004),Vector3(sign_x*.028,1.20,front(1.20)+.004),chest)
		triangle(shirt,Vector3(sign_x*.028,1.61,.067),Vector3(sign_x*.083,1.565,front(1.565)+.006),Vector3(sign_x*.026,1.505,front(1.505)+.008),chest)
	var mesh:=ArrayMesh.new()
	var colors: Array=[Color("202c40") if team==0 else Color("303238"),Color("e7e9ed"),Color("222833"),Color("344157") if team==0 else Color("41434a")]
	for i in 4:
		var st: SurfaceTool=[jacket,shirt,trousers,details][i]
		st.generate_normals();st.index();st.commit(mesh);mesh.surface_set_material(i,material(colors[i]))
	meshes[key]=mesh;return mesh
static func dress(actor,rig,team: int):
	var transparent:=material(Color(0,0,0,0));transparent.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	actor.body_parts.body.set_surface_override_material(7,transparent)
	actor.body_parts.body.set_surface_override_material(5,material(Color("e7e9ed")))
	actor.body_parts.body.set_surface_override_material(4,material(Color("171b22"),.52))
	# Hide the original short-sleeved forearms beneath the tailored sleeves only
	# through geometry coverage; hands and the source head remain untouched.
	var garment:=MeshInstance3D.new();garment.name="CoachSuit103";actor.visual_root.add_child(garment)
	garment.mesh=build(rig,team);garment.skin=actor.skeleton.create_skin_from_rest_transforms();garment.skeleton=garment.get_path_to(actor.skeleton)
	garment.extra_cull_margin=1.5
