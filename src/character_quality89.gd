extends RefCounted
var actor
var original: Dictionary={}
var detail:=2
var level_meshes: Dictionary={}
func attach(player):
	actor=player
	for part in ["body","head","cloth"]:
		original[part]=actor.body_parts[part].mesh
	actor.set_meta("visual_quality89",self)
func quality(level: int):
	detail=level;apply()
func apply():
	if not is_instance_valid(actor):return
	if detail>=2:
		actor.body_parts.body.mesh=load("res://assets/art/athlete87/body.res")
		actor.body_parts.head.mesh=load("res://assets/art/visual86/prototype_head.res")
	else:
		actor.body_parts.body.mesh=original.body;actor.body_parts.head.mesh=original.head
	var mesh: Mesh=original.cloth
	if detail>0:mesh=load("res://assets/art/athlete88/cloth.res" if detail==3 else "res://assets/art/athlete87/cloth.res")
	actor.body_parts.cloth.mesh=preload("res://src/club_kits.gd").mesh_with_print_uv(mesh)
