extends Node3D
## Original referee mesh and native, pre-baked PSA gestures. No match authority.
const PSK=preload("res://src/psk.gd")
const Assets=preload("res://src/source_assets.gd")
var player: AnimationPlayer
var cue:=""
var gestures_started:=0
var watch:=0.0
var last_sets: Array=[]
func _ready() -> void:
	name="FirstReferee"
	var model=PSK.new(); assert(model.load_file("res://assets/art/officials46/referee.psk"))
	var rig:=Skeleton3D.new(); rig.name="Rig"; add_child(rig)
	for i in model.names.size():
		rig.add_bone(model.names[i])
		if i>0: rig.set_bone_parent(i,model.parents[i])
		rig.set_bone_rest(i,model.rest[i])
	rig.reset_bone_poses()
	var mesh:=MeshInstance3D.new(); mesh.mesh=model.mesh; mesh.skin=rig.create_skin_from_rest_transforms(); add_child(mesh); mesh.skeleton=mesh.get_path_to(rig)
	var descriptions: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/art/officials46/materials.json"))
	for i in model.material_names.size():
		var key: String=model.material_names[i]; var textures: Dictionary=descriptions[key]
		var mat:=Assets.material(textures.get("Diffuse",""),textures.get("Normal",""),Color.WHITE,.78)
		mat.cull_mode=BaseMaterial3D.CULL_DISABLED
		if "Eyelashes" in key or "Occlusion" in key:
			mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR; mat.alpha_scissor_threshold=.4
		mesh.set_surface_override_material(i,mat)
	player=AnimationPlayer.new(); player.name="Gestures"; add_child(player)
	player.add_animation_library("",load("res://assets/art/officials46/gestures.res"))
	player.animation_finished.connect(func(_clip): player.play("idle",.23))
	player.play("idle"); player.advance(0)
func _process(dt: float) -> void:
	var game=get_parent().get_parent().get_parent()
	var match_ended: bool=game.get("phase")=="POINT" and str(game.get("point_reason")).begins_with("VITTORIA")
	if game.get("started")!=true or (game.get("paused")==true and not match_ended):
		player.pause(); return
	if not player.is_playing(): player.play()
	var key:=str([game.phase,game.server,game.scores,game.sets])
	if key==cue: return
	cue=key
	var set_ended: bool=not last_sets.is_empty() and last_sets!=game.sets
	last_sets=game.sets.duplicate()
	if game.phase=="SERVE": signal_gesture("serve_left" if game.server==0 else "serve_right")
	elif game.phase=="POINT":
		# Native point_left extends +localX -> -worldZ at this left-side stand.
		signal_gesture("end_set" if set_ended else ("point_right" if game.server==0 else "point_left"))
	elif game.phase in ["MATCH_OVER","SET_END"]: signal_gesture("end_set")
	elif str(player.current_animation).begins_with("serve_"): player.play("idle",.20)
func signal_gesture(gesture: String) -> void:
	if not player.has_animation(gesture): return
	player.play(gesture,.20); gestures_started+=1
