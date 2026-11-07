extends SceneTree
const Refine=preload("res://tools/Athlete87MeshRefinement.gd")
var author
var stats: Dictionary={}
func _initialize():call_deferred("run")
func run():
	# Reuse offline authoring functions only; never run the 0.87 build entry.
	var code:=GDScript.new();var text:=FileAccess.get_file_as_string("res://tools/Build-Athlete87.gd")
	text=text.replace("extends SceneTree","extends RefCounted")
	var begin:=text.find("func _initialize():");var end:=text.find("func save(")
	text=text.substr(0,begin)+text.substr(end)
	text=text.replace("func strand_mesh(","func old_strand_mesh(")
	text=text.replace("random.randf_range(.003,.008) if beard","random.randf_range(.00065,.0018) if beard")
	text+=FileAccess.get_file_as_string("res://tools/Groom88.gdpart")
	code.source_code=text;assert(code.reload()==OK);author=code.new();author.random.seed=88031
	author.body=load("res://src/psk.gd").new();assert(author.body.load_file("res://assets/active/body.psk"))
	var document=ClassDB.instantiate("FBXDocument");var state=ClassDB.instantiate("FBXState")
	assert(document.append_from_file("res://assets/art/athlete88/source/Head.fbx",state)==OK)
	var scene=document.generate_scene(state);root.add_child(scene)
	var source: MeshInstance3D=scene.find_children("*","MeshInstance3D",true,false)[0]
	var a=source.mesh.surface_get_arrays(0).duplicate(true);var v: PackedVector3Array=a[Mesh.ARRAY_VERTEX];var n: PackedVector3Array=a[Mesh.ARRAY_NORMAL]
	var b:=PackedInt32Array();var w:=PackedFloat32Array()
	for i in v.size():
		var p: Vector3=source.global_transform*v[i]
		p=Vector3(p.x*50,1.473+p.y*50,p.z*38)
		# Fit the lower neck to the existing collar without moving any bone.
		var neck:=1-smoothstep(1.58,1.68,p.y)
		var radius:=Vector2(p.x,(p.z+.005)*1.15).length()
		if radius>.056 and neck>0:
			var scale: float=lerpf(1.0,.056/radius,neck);p.x*=scale;p.z=(p.z+.005)*scale-.005
		var under_collar:=1-smoothstep(1.59,1.645,p.y)
		p.z=lerpf(p.z,minf(p.z,-.028),under_collar)
		v[i]=p;n[i]=Vector3(n[i].x/50,n[i].y/50,n[i].z/38).normalized()
		var head:=smoothstep(1.57,1.645,p.y)
		b.append_array(PackedInt32Array([6,5,0,0]));w.append_array(PackedFloat32Array([head,1-head,0,0]))
	a[Mesh.ARRAY_VERTEX]=v;a[Mesh.ARRAY_NORMAL]=n;a[Mesh.ARRAY_BONES]=b;a[Mesh.ARRAY_WEIGHTS]=w;a[Mesh.ARRAY_TANGENT]=null
	var mesh:=ArrayMesh.new();mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,a)
	var refined: ArrayMesh=Refine.new().refine(mesh,"scan")
	var face:=cut_eyes_and_neck(refined)
	save("head",face);save("eyes",eyes())
	# The groom is resampled on the scan surface, never pasted in world space.
	save("hair",author.fibers(face,false));save("beard",author.fibers(face,true))
	var body: ArrayMesh=load("res://assets/art/athlete87/body.res")
	save("body",muscle_surface(body))
	save("cloth",garment_surface(load("res://assets/art/athlete87/cloth.res")))
	save("seams",seams(load("res://assets/art/athlete87/cloth.res")))
	FileAccess.open("res://docs/athlete88-build.json",FileAccess.WRITE).store_string(JSON.stringify({"pass":true,"source":"Infinite scan by Lee Perry-Smith, CC BY 3.0; converted by McGuire/Cardenas/Keijiro","method":"scan anatomy, actual eyelid opening, existing Head/Neck skinning, resampled groom, anatomical body and cloth relief","parts":stats,"groom":author.stats,"unchanged_skeleton_bones":115},"  "))
	print("ATHLETE88 BUILD PASS ",JSON.stringify(stats));scene.free();quit()
func save(part: String,mesh: ArrayMesh):
	assert(ResourceSaver.save(mesh,"res://assets/art/athlete88/"+part+".res",ResourceSaver.FLAG_COMPRESS)==OK)
	var tris:=0
	for s in mesh.get_surface_count():tris+=maxi(mesh.surface_get_array_index_len(s),mesh.surface_get_array_len(s))/3
	stats[part]={"triangles":tris,"bounds":str(mesh.get_aabb())}
func signed_keep(p: Vector3) -> float:
	if p.z<.052:return p.y-1.535
	var dx:=absf(p.x)-.0345;var dy:=p.y-1.775-dx*.08
	var height:=.0048 if dy>0 else .0035
	var opening: float=maxf(absf(dx)/.0142-1,absf(dy)/height-(1-pow(dx/.0142,2)))*.008
	return minf(p.y-1.535,opening)
func mix_vertex(a: Dictionary,b: Dictionary,t: float) -> Dictionary:
	return {"v":a.v.lerp(b.v,t),"n":a.n.lerp(b.n,t).normalized(),"uv":a.uv.lerp(b.uv,t)}
func cut_eyes_and_neck(mesh: ArrayMesh) -> ArrayMesh:
	var a=mesh.surface_get_arrays(0);var v: PackedVector3Array=a[Mesh.ARRAY_VERTEX];var n: PackedVector3Array=a[Mesh.ARRAY_NORMAL];var uv: PackedVector2Array=a[Mesh.ARRAY_TEX_UV];var indices: PackedInt32Array=a[Mesh.ARRAY_INDEX]
	var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for face in range(0,indices.size(),3):
		var polygon: Array=[]
		for j in 3:
			var id: int=indices[face+j];polygon.append({"v":v[id],"n":n[id],"uv":uv[id]})
		var clipped: Array=[];var intersections: Array=[]
		for j in 3:
			var p: Dictionary=polygon[j];var q: Dictionary=polygon[(j+1)%3];var dp:=signed_keep(p.v);var dq:=signed_keep(q.v)
			if dp>=0:clipped.append(p)
			if (dp>=0)!=(dq>=0):
				var cut:=mix_vertex(p,q,dp/(dp-dq));clipped.append(cut);intersections.append(cut)
		for j in range(1,clipped.size()-1):
			for p in [clipped[0],clipped[j],clipped[j+1]]:
				var head:=smoothstep(1.57,1.645,p.v.y)
				st.set_normal(p.n);st.set_uv(p.uv);st.set_bones(PackedInt32Array([6,5,0,0]));st.set_weights(PackedFloat32Array([head,1-head,0,0]));st.add_vertex(p.v)
		if intersections.size()==2 and intersections[0].v.y>1.75 and intersections[0].v.y<1.80:
			var rim: Array=[]
			for edge in intersections:
				var inset: Dictionary=edge.duplicate();var center:=Vector3(signf(edge.v.x)*.0345,1.775,edge.v.z)
				inset.v=edge.v+(center-edge.v).normalized()*.00045+Vector3(0,0,-.0008)
				rim.append(inset)
			for p in [intersections[0],intersections[1],rim[1],intersections[0],rim[1],rim[0]]:
				st.set_normal(p.n);st.set_uv(p.uv);st.set_bones(PackedInt32Array([6,0,0,0]));st.set_weights(PackedFloat32Array([1,0,0,0]));st.add_vertex(p.v)
	st.index();st.generate_tangents();return st.commit()
func eyes() -> ArrayMesh:
	var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for side in [-1,1]:
		var sphere:=SphereMesh.new();sphere.radius=.012;sphere.height=.024;sphere.radial_segments=40;sphere.rings=24
		var a=sphere.get_mesh_arrays();var points: PackedVector3Array=a[Mesh.ARRAY_VERTEX];var normals: PackedVector3Array=a[Mesh.ARRAY_NORMAL];var indices: PackedInt32Array=a[Mesh.ARRAY_INDEX]
		for id in indices:
			var p:=points[id]
			st.set_uv(Vector2(.5+p.x/.026,.5-p.y/.026));st.set_normal(normals[id]);st.set_bones(PackedInt32Array([6,0,0,0]));st.set_weights(PackedFloat32Array([1,0,0,0]))
			st.add_vertex(p+Vector3(side*.0345,1.775,.0845))
	st.index();return st.commit()
func muscle_surface(mesh: ArrayMesh) -> ArrayMesh:
	var a=mesh.surface_get_arrays(0).duplicate(true);var v: PackedVector3Array=a[Mesh.ARRAY_VERTEX];var n: PackedVector3Array=a[Mesh.ARRAY_NORMAL]
	for i in v.size():
		var p:=v[i];var arm:=exp(-pow((absf(p.x)-.30)/.11,2)-pow((p.y-1.30)/.17,2))
		var calf:=exp(-pow((absf(p.x)-.12)/.09,2)-pow((p.y-.47)/.13,2))
		var wrist:=exp(-pow((absf(p.x)-.51)/.07,2)-pow((p.y-1.02)/.09,2))
		v[i]+=n[i]*(.0025*arm+.0020*calf+.0007*wrist)
	a[Mesh.ARRAY_VERTEX]=v;var out:=ArrayMesh.new();author.rebuild(a,out);return out
func garment_surface(mesh: ArrayMesh) -> ArrayMesh:
	var refined: ArrayMesh=Refine.new().refine(mesh,"cloth")
	var a=refined.surface_get_arrays(0).duplicate(true);var v: PackedVector3Array=a[Mesh.ARRAY_VERTEX];var n: PackedVector3Array=a[Mesh.ARRAY_NORMAL]
	for i in v.size():
		var p:=v[i];var folds:=exp(-pow((p.y-1.10)/.11,2))
		var ripple: float=.0013*folds*sin(p.y*180+absf(p.x)*32+p.z*22)
		v[i]+=n[i]*ripple
	a[Mesh.ARRAY_VERTEX]=v;var out:=ArrayMesh.new();author.rebuild(a,out);return out
func seams(mesh: ArrayMesh) -> ArrayMesh:
	var a=mesh.surface_get_arrays(0);var points: PackedVector3Array=a[Mesh.ARRAY_VERTEX];var normals: PackedVector3Array=a[Mesh.ARRAY_NORMAL];var uv: PackedVector2Array=a[Mesh.ARRAY_TEX_UV];var ids: PackedInt32Array=a[Mesh.ARRAY_INDEX]
	var bones: PackedInt32Array=a[Mesh.ARRAY_BONES];var weights: PackedFloat32Array=a[Mesh.ARRAY_WEIGHTS]
	var keys: Array=[];var edges: Dictionary={}
	for p in points:keys.append(str(p.snapped(Vector3.ONE*.00001)))
	for face in range(0,ids.size(),3):
		for k in 3:
			var i: int=ids[face+k];var j: int=ids[face+(k+1)%3]
			var key: String=(keys[i]+":"+keys[j]) if keys[i]<keys[j] else (keys[j]+":"+keys[i])
			if not edges.has(key):edges[key]={"count":0,"i":i,"j":j}
			edges[key].count+=1
	var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for edge in edges.values():
		if edge.count!=1:continue
		var i: int=edge.i;var j: int=edge.j
		var tangent: Vector3=(points[j]-points[i]).normalized()
		var sideways: Vector3=tangent.cross(normals[i]).normalized()
		for segment in 6:
			var n0: Vector3=normals[i]*cos(TAU*segment/6)+sideways*sin(TAU*segment/6)
			var n1: Vector3=normals[i]*cos(TAU*(segment+1)/6)+sideways*sin(TAU*(segment+1)/6)
			for item in [[i,n0],[j,n0],[j,n1],[i,n0],[j,n1],[i,n1]]:
				var id: int=item[0]
				st.set_normal(item[1]);st.set_uv(uv[id]);st.set_uv2(Vector2(-1,-1));st.set_bones(bones.slice(id*4,id*4+4));st.set_weights(weights.slice(id*4,id*4+4));st.add_vertex(points[id]+normals[id]*.0003+item[1]*.00075)
	st.index();return st.commit()
