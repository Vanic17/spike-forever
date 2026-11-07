extends RefCounted
func refine(source: ArrayMesh,part: String) -> ArrayMesh:
	var result:=ArrayMesh.new()
	for surface in source.get_surface_count():
		var a: Array=source.surface_get_arrays(surface).duplicate(true)
		var v: PackedVector3Array=a[Mesh.ARRAY_VERTEX];var n: PackedVector3Array=a[Mesh.ARRAY_NORMAL]
		var uv: PackedVector2Array=a[Mesh.ARRAY_TEX_UV];var bones: PackedInt32Array=a[Mesh.ARRAY_BONES];var weights: PackedFloat32Array=a[Mesh.ARRAY_WEIGHTS]
		var original: PackedInt32Array=a[Mesh.ARRAY_INDEX];var indices:=PackedInt32Array();var edges: Dictionary={}
		# Correct only the lower neck's overlap with the collar, not the skeleton.
		if part=="head":
			for i in v.size():
				var fit: float=1.0-smoothstep(1.53,1.635,v[i].y)
				v[i].x*=1.0-fit*.14;v[i].z*=1.0-fit*.14
		for face in range(0,original.size(),3):
			var corners: Array[int]=[original[face],original[face+1],original[face+2]];var mids: Array[int]=[]
			for edge in 3:
				var i:=corners[edge];var j:=corners[(edge+1)%3];var key:=Vector2i(mini(i,j),maxi(i,j))
				if not edges.has(key):
					var p: Vector3=(v[i]+v[j])*.5
					var b1: Vector3=(v[i]*2+v[j]-(v[j]-v[i]).dot(n[i])*n[i])/3
					var b2: Vector3=(v[j]*2+v[i]-(v[i]-v[j]).dot(n[j])*n[j])/3
					var curved: Vector3=(v[i]+b1*3+b2*3+v[j])/8
					var maximum:=.0012 if part=="head" else .0007
					# Preserve silhouettes around the open neck boundary.
					if part=="head":maximum*=smoothstep(1.59,1.65,p.y)
					p+=(curved-p).limit_length(maximum)
					var id:=v.size();edges[key]=id;v.append(p);n.append((n[i]+n[j]).normalized());uv.append((uv[i]+uv[j])*.5)
					var influences: Dictionary={}
					for point in [i,j]:
						for k in 4:
							var bone: int=bones[point*4+k];influences[bone]=float(influences.get(bone,0.0))+weights[point*4+k]*.5
					var ids: Array=influences.keys();ids.sort_custom(func(x,y):return influences[x]>influences[y])
					var total:=0.0
					for k in mini(4,ids.size()):total+=float(influences[ids[k]])
					for k in 4:
						bones.append(int(ids[k]) if k<ids.size() else 0);weights.append(float(influences[ids[k]])/total if k<ids.size() else 0)
				mids.append(edges[key])
			indices.append_array(PackedInt32Array([corners[0],mids[0],mids[2],mids[0],corners[1],mids[1],mids[2],mids[1],corners[2],mids[0],mids[1],mids[2]]))
		a[Mesh.ARRAY_VERTEX]=v;a[Mesh.ARRAY_NORMAL]=n;a[Mesh.ARRAY_TEX_UV]=uv;a[Mesh.ARRAY_BONES]=bones;a[Mesh.ARRAY_WEIGHTS]=weights;a[Mesh.ARRAY_INDEX]=indices;a[Mesh.ARRAY_TANGENT]=null
		var temp:=ArrayMesh.new();temp.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,a)
		var builder:=SurfaceTool.new();builder.create_from(temp,0);builder.generate_tangents();builder.commit(result)
	return result
