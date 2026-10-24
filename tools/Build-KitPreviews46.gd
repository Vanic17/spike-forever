extends "res://tools/Preview-Kits45.gd"
func setup() -> void:
	super.setup()
func show_club() -> void:
	super.show_club()
	for i in 6:
		var actor=game.players[i]
		for part in actor.body_parts:
			actor.body_parts[part].visible=part=="cloth"
		var original: ShaderMaterial=actor.cloth_material
		var fabric:=StandardMaterial3D.new()
		fabric.albedo_texture=original.get_shader_parameter("fabric")
		fabric.normal_enabled=true; fabric.normal_texture=original.get_shader_parameter("fabric_normal")
		fabric.normal_scale=.45; fabric.roughness=.86; fabric.cull_mode=BaseMaterial3D.CULL_DISABLED
		actor.body_parts.cloth.material_override=fabric
func _process(_dt: float) -> bool:
	if game==null: return false
	age+=1
	if age==20:
		RenderingServer.frame_post_draw.connect(func():
			var image:=root.get_texture().get_image()
			DirAccess.make_dir_recursive_absolute("res://assets/ui/kits46")
			var entries: Dictionary=load("res://src/club_kits.gd").data().clubs[club].variants
			for i in 3:
				var variant: String=["home","away","libero"][i]
				if not entries.has(variant): continue
				# Native engine rendering, cropped around torso/shorts. No AI
				# redraw and no photograph margins or frozen player identity.
				var portrait:=image.get_region(Rect2i(i*800,265,800,380))
				portrait.resize(640,304,Image.INTERPOLATE_LANCZOS)
				portrait.save_png("res://assets/ui/kits46/"+club+"-"+variant+".png")
			print("KIT PREVIEW46 SAVED ",club)
			if pending.is_empty(): quit()
			else: club=pending.pop_front(); age=0; show_club()
		,CONNECT_ONE_SHOT)
	return false
