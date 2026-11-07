extends SceneTree
## Bake fitted, weighted cloth shells from the source body; clip the hems in
## bind space, retaining interpolated skin weights at every clipped vertex.
const PSK=preload("res://src/psk.gd")
var body
func _initialize():
	body=PSK.new();assert(body.load_file("res://assets/active/body.psk"))
	DirAccess.make_dir_recursive_absolute("res://assets/art/wear90")
	for side in ["Left","Right"]:
		for length in 3:bake(side,"sock"+str(length),.105,[.23,.34,.46][length],.0025)
		bake(side,"pad",.44,.62,.006)
		bake(side,"sleeve",.27,.71,.003)
	var shoes=PSK.new();assert(shoes.load_file("res://assets/active/shoes.psk",body.names))
	for kind in 4:
		var mesh=ArrayMesh.new()
		for surface in shoes.mesh.get_surface_count():
			var a=shoes.mesh.surface_get_arrays(surface);var verts: PackedVector3Array=a[Mesh.ARRAY_VERTEX]
			for i in verts.size():
				var v:=verts[i];var side:=1.0 if v.x>0 else -1.0
				var centre:=side*.1757;var toe: float=clampf((v.z+.04)/.18,0,1)
				v.x=centre+(v.x-centre)*[1.0,.91,1.10,1.04][kind]
				if kind==1:v.z+=toe*.014
				if kind==2:v.y+=clampf((v.y-.025)/.10,0,1)*.008
				if kind==3:v.y+=clampf((v.y-.04)/.07,0,1)*.022*(1.0-toe)
				verts[i]=v
			a[Mesh.ARRAY_VERTEX]=verts
			var st=SurfaceTool.new();st.create_from_arrays(a,Mesh.PRIMITIVE_TRIANGLES);st.generate_normals();st.generate_tangents();st.commit(mesh)
		assert(ResourceSaver.save(mesh,"res://assets/art/wear90/shoe%d.res"%kind)==OK)
	print("WEAR90: 10 fitted leg shells, four distinct shoe silhouettes baked")
	quit()
func interpolate(a: Dictionary,b: Dictionary,t: float) -> Dictionary:
	var weights: Dictionary={}
	for i in 4:
		weights[a.b[i]]=weights.get(a.b[i],0.0)+a.w[i]*(1-t)
		weights[b.b[i]]=weights.get(b.b[i],0.0)+b.w[i]*t
	var keys=weights.keys();keys.sort_custom(func(x,y):return weights[x]>weights[y])
	var bones=PackedInt32Array([0,0,0,0]);var values=PackedFloat32Array([0,0,0,0]);var total:=0.0
	for i in mini(4,keys.size()):bones[i]=keys[i];values[i]=weights[keys[i]];total+=values[i]
	for i in 4:values[i]/=maxf(.0001,total)
	return {"p":a.p.lerp(b.p,t),"n":a.n.lerp(b.n,t).normalized(),"uv":a.uv.lerp(b.uv,t),"b":bones,"w":values}
func clip(poly: Array,y: float,above: bool) -> Array:
	var out: Array=[]
	for i in poly.size():
		var a=poly[i];var b=poly[(i+1)%poly.size()]
		var inside_a: bool=a.p.y>=y if above else a.p.y<=y
		var inside_b: bool=b.p.y>=y if above else b.p.y<=y
		if inside_a:out.append(a)
		if inside_a!=inside_b:out.append(interpolate(a,b,(y-a.p.y)/(b.p.y-a.p.y)))
	return out
func bake(side: String,kind: String,lo: float,hi: float,offset: float):
	var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var sign_x:=1.0 if side=="Left" else -1.0
	for surface in body.mesh.get_surface_count():
		var a=body.mesh.surface_get_arrays(surface);var indices=a[Mesh.ARRAY_INDEX]
		for f in range(0,indices.size(),3):
			var poly: Array=[];var centre:=Vector3.ZERO
			for j in 3:
				var i: int=indices[f+j];var v: Vector3=a[Mesh.ARRAY_VERTEX][i];centre+=v/3
				poly.append({"p":v,"n":a[Mesh.ARRAY_NORMAL][i],"uv":a[Mesh.ARRAY_TEX_UV][i],"b":PackedInt32Array(a[Mesh.ARRAY_BONES].slice(i*4,i*4+4)),"w":PackedFloat32Array(a[Mesh.ARRAY_WEIGHTS].slice(i*4,i*4+4))})
			if centre.x*sign_x<.055 or centre.y<lo-.10 or centre.y>hi+.10:continue
			poly=clip(clip(poly,lo,true),hi,false)
			if poly.size()<3:continue
			for j in range(1,poly.size()-1):
				for v in [poly[0],poly[j],poly[j+1]]:
					var foam: float=.018*pow(maxf(0,v.n.z),2)*exp(-pow((v.p.y-.535)/.065,4)) if kind in ["pad","sleeve"] else 0.0
					st.set_normal(v.n);st.set_uv(v.uv*Vector2(8,16));st.set_bones(v.b);st.set_weights(v.w)
					st.add_vertex(v.p+v.n*(offset+foam))
	st.index();st.generate_tangents()
	var mesh=st.commit();assert(mesh!=null)
	assert(ResourceSaver.save(mesh,"res://assets/art/wear90/"+side+"_"+kind+".res")==OK)
