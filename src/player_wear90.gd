extends RefCounted
## Shared weighted meshes: no procedural geometry, file IO or per-bone work in
## the frame loop. Stable identity choices also cover reserves and replays.
const Assets=preload("res://src/source_assets.gd")
static var meshes: Dictionary={}
static var materials: Dictionary={}
static var outfits: Dictionary={}
static func mesh(key: String) -> Mesh:
	if not meshes.has(key):meshes[key]=load("res://assets/art/wear90/"+key+".res")
	return meshes[key]
static func fabric(color: Color) -> StandardMaterial3D:
	var key:=color.to_html()
	if materials.has(key):return materials[key]
	var m=StandardMaterial3D.new();m.albedo_color=color;m.roughness=.91
	m.normal_texture=Assets.texture("T_Char_Cloth_MyTeam_Normal.png");m.normal_enabled=m.normal_texture!=null;m.normal_scale=.25
	materials[key]=m;return m
static func apply(actor) -> void:
	if actor.skeleton==null or not actor.body_parts.has("head"):return
	var person: Dictionary=actor.libero_identity if actor.libero_active else actor.roster_identity
	var identity: String=str(person.get("database_id",person.get("id","")))
	if identity.contains("|"):identity=identity.get_slice("|",1)
	if identity.is_empty():identity="athlete-%s-%s"%[actor.team,actor.number]
	var seed: int=absi(identity.hash());var sock_type: int=seed%3
	var protected: bool=actor.libero_active or person.get("role","")=="libero" or seed%12!=0
	var kit: Dictionary=actor.libero_kit if actor.libero_active else actor.kit_identity
	var primary:=Color(kit.get("primary_hex_approx","#17458a"))
	var sock_color:=Color("eceee9") if seed%3!=0 else Color("20252b")
	var pad_color: Color=Color("20252b") if seed%4<2 else (Color("e6e8e4") if primary.get_luminance()>.45 else primary.lightened(.09))
	var key: String=identity+":"+str(actor.libero_active)+":"+str(protected)+":"+primary.to_html()
	if actor.get_meta("wear90_key","")!=key:
		var nodes: Array=actor.get_meta("wear90_nodes",[])
		for node in nodes:node.get_parent().remove_child(node);node.queue_free()
		nodes=[];var pieces: Array=[]
		for side in ["Left","Right"]:
			pieces.append([side+"_sock"+str(sock_type),sock_color])
			if protected:
				var long_sleeve: bool=seed%5==0 or (seed%5==1 and side=="Left") or (seed%5==2 and side=="Right")
				pieces.append([side+("_sleeve" if long_sleeve else "_pad"),pad_color])
		var outfit_key: String=str(pieces)
		if not outfits.has(outfit_key):outfits[outfit_key]=combine(pieces)
		var node=MeshInstance3D.new();node.name="Legwear90";node.mesh=outfits[outfit_key]
		actor.visual_root.add_child(node);node.skin=actor.body_parts.body.skin;node.skeleton=node.get_path_to(actor.skeleton)
		node.material_override=fabric(Color.WHITE);node.layers=actor.body_parts.head.layers;node.extra_cull_margin=3
		nodes.append(node);actor.set_meta("wear90_pieces",pieces.map(func(piece):return piece[0]))
		actor.set_meta("wear90_nodes",nodes);actor.set_meta("wear90_key",key)
	for node in actor.get_meta("wear90_nodes",[]):node.layers=actor.body_parts.head.layers
	var shoes=actor.body_parts.get("shoes")
	if shoes==null:return
	shoes.mesh=mesh("shoe"+str(seed%4))
	var material_key: String="shoe:"+str(seed%12)
	if not materials.has(material_key):
		var m=StandardMaterial3D.new();m.roughness=.64
		m.albedo_texture=Assets.texture(["SK_Char_Shoe_M_01_Base02.png","SK_Char_Shoe_M_01_Base05.png","SK_Char_Shoe_M_01_Base08.png"][seed%3])
		m.albedo_color=[Color("fafaf5"),Color("727d89"),Color("cdda59"),Color("e8a681")][(seed/3)%4]
		m.normal_texture=Assets.texture("SK_Char_Shoe_M_01_Normal.png");m.normal_enabled=m.normal_texture!=null
		materials[material_key]=m
	shoes.material_override=materials[material_key]
	actor.set_meta("shoe_model90",seed%4)
static func combine(pieces: Array) -> Mesh:
	# One draw per athlete for both socks and both pads, rather than four
	# separately skinned render instances. Preserve all source skin weights.
	var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for piece in pieces:
		var source: Mesh=mesh(piece[0]);var color: Color=piece[1].srgb_to_linear()
		for surface in source.get_surface_count():
			var a=source.surface_get_arrays(surface)
			for index in a[Mesh.ARRAY_INDEX]:
				st.set_color(color);st.set_normal(a[Mesh.ARRAY_NORMAL][index]);st.set_uv(a[Mesh.ARRAY_TEX_UV][index])
				st.set_bones(PackedInt32Array(a[Mesh.ARRAY_BONES].slice(index*4,index*4+4)))
				st.set_weights(PackedFloat32Array(a[Mesh.ARRAY_WEIGHTS].slice(index*4,index*4+4)))
				st.add_vertex(a[Mesh.ARRAY_VERTEX][index])
	st.index();st.generate_tangents();var result=st.commit()
	fabric(Color.WHITE).vertex_color_use_as_albedo=true
	return result
