extends SceneTree
func _initialize(): call_deferred("run")
func press(menu,action: String):
	var event=InputEventAction.new(); event.action=action; event.pressed=true; menu._input(event)
func run():
	var g=load("res://src/main.tscn").instantiate(); root.add_child(g)
	g.set_process(false); g.set_physics_process(false); g.self_test=true
	await process_frame
	var host
	for child in g.get_children():
		if child.get_script()==load("res://src/start_menu.gd"): host=child
	assert(host!=null and host.settings_button.text=="IMPOSTAZIONI")
	var service=g.preferences; service.dry_run=true; service.config_path="user://settings53-check.cfg"
	var original: Dictionary=service.data.duplicate(true)
	var original_displays: Array=service.displays.duplicate(true); var original_device: String=service.active_device; var original_monitor: Dictionary=service.original_mode.duplicate(true)
	for resolution in [Vector2i(1920,1080),Vector2i(2560,1440),Vector2i(3840,2160),Vector2i(3440,1440)]:
		service.active_device="test-monitor"; service.original_mode={"width":resolution.x,"height":resolution.y,"hz":60}
		service.displays=[{"device":"test-monitor","current":{"width":resolution.x,"height":resolution.y,"hz":60},"native":{"width":resolution.x,"height":resolution.y,"hz":60},"modes":[{"width":resolution.x,"height":resolution.y,"hz":60}]}]
		assert(service.automatic_resolution(2)==resolution and service.automatic_resolution(1)==resolution,"Full HD, QHD, 4K and ultrawide must adapt without a fixed 1080p assumption")
	service.displays=original_displays; service.active_device=original_device; service.original_mode=original_monitor
	var before_ball: Vector3=g.ball_pos; var before_velocity: Vector3=g.ball_vel; var before_rotation: Array=g.rotations.duplicate(); var physics: int=Engine.physics_ticks_per_second
	var candidate: Dictionary=original.duplicate(true)
	candidate.merge({"language":"en","textures":512,"scale":.67,"scaling_mode":1,"fps":90,"vsync":0,"aa":1,"taa":true,"shadows":0,"shadow_distance":30.0,"ssao":false,"ssil":true,"ssr":true,"exposure":1.2,"glow":false,"crowd":0,"anisotropy":1},true)
	assert(service.apply(candidate,false)); assert(service.save_config()==OK)
	assert(service.save_config()==OK,"Saving again must replace the previous local settings atomically")
	assert(Engine.max_fps==90 and root.msaa_3d==1 and root.use_taa and is_equal_approx(root.scaling_3d_scale,.67) and root.anisotropic_filtering_level==1)
	assert(root.scaling_3d_mode==1)
	assert(g.ball_pos==before_ball and g.ball_vel==before_velocity and g.rotations==before_rotation and Engine.physics_ticks_per_second==physics)
	var environments=0; var crowds=0; var lights=0
	for node in g.find_children("*","WorldEnvironment",true,false): assert(not node.environment.ssao_enabled and not node.environment.glow_enabled and node.environment.ssil_enabled and node.environment.ssr_enabled and is_equal_approx(node.environment.tonemap_exposure,1.2)); environments+=1
	for node in g.find_children("*","DirectionalLight3D",true,false): assert(not node.shadow_enabled and is_equal_approx(node.directional_shadow_max_distance,30.0)); lights+=1
	for node in g.find_children("*","MultiMeshInstance3D",true,false):
		if node.has_meta("spectators"): assert(node.multimesh.visible_instance_count==roundi(node.multimesh.instance_count*.35)); crowds+=1
	assert(environments>0 and crowds>0 and lights>0)
	var reloaded=load("res://src/app_settings.gd").new(); reloaded.config_path=service.config_path; reloaded.load_config()
	assert(reloaded.data==service.data); reloaded.free()
	print("LANG53 locale=",TranslationServer.get_locale()," raw=",service.translation.get_message("GIOCA")," translate=",TranslationServer.translate("GIOCA")," count=",load("res://src/localization.gd").catalogue.size()," resource_locale=",service.translation.locale)
	assert(TranslationServer.translate("GIOCA")=="PLAY")
	assert(TranslationServer.translate("Qualità ricezione 84%")=="Reception quality 84%")
	assert(TranslationServer.translate("Precisione 80% · fascia oro 97–100% vincente")=="Accuracy 80% · 97–100% winning gold zone")
	assert(TranslationServer.translate("OH / BANDA")=="OH / OUTSIDE HITTER")
	assert(TranslationServer.translate("ALZATA VELOCE")=="QUICK SET")
	assert(TranslationServer.translate("Rischio errore 12%")=="Error risk 12%")
	assert(TranslationServer.translate("X / CROCE normale   QUADRATO veloce   CERCHIO seconda")=="X / CROSS normal   SQUARE quick   CIRCLE dump")
	assert(TranslationServer.translate("Casa")=="Home" and TranslationServer.translate("rasati")=="buzz cut")
	host.clubs.editor(); host.clubs.enter_details()
	assert(host.clubs.inputs.role.get_item_text(host.clubs.inputs.role.selected) in ["outside_hitter","middle_blocker","opposite","setter","libero"],"Translation must never change persisted role IDs")
	host.clubs.hide()
	var menu=host.settings_menu; menu.open(); menu.video_tab.grab_focus()
	var navigation: Array=[]
	for i in 20:
		press(menu,"ui_down"); var owner=root.gui_get_focus_owner()
		navigation.append(owner.text if owner is Button else str(owner))
	assert(root.gui_get_focus_owner()==menu.back_button)
	menu.show_page(1); menu.graphics_tab.grab_focus()
	menu.fields.preset.select(1); menu.fields.preset.item_selected.emit(1)
	assert(menu.draft.textures==512 and menu.draft.scaling_mode==1 and not menu.draft.ssil,"Low preset must populate real graphics controls")
	menu.fields.preset.select(4); menu.fields.preset.item_selected.emit(4)
	assert(menu.draft.shadows==3 and menu.draft.ssil and menu.draft.ssr and menu.draft.anisotropy==4,"Ultra preset must populate real graphics controls")
	for i in 20: press(menu,"ui_down")
	assert(root.gui_get_focus_owner()==menu.back_button,"Controller must reach the footer after every graphics option")
	menu.fields.preset.grab_focus(); press(menu,"ui_up"); assert(root.gui_get_focus_owner()==menu.graphics_tab)
	press(menu,"ui_cancel"); assert(not menu.visible and root.gui_get_focus_owner()==host.settings_button)
	menu.open(); menu.show_page(1); menu.draft.mode=0 if candidate.mode!=0 else 1; menu.draft.width=1280; menu.draft.height=720
	await menu.apply_changes()
	assert(menu.pending,"Display changes require timed confirmation")
	menu.deadline=Time.get_ticks_msec()-1; menu._process(0)
	assert(not menu.pending and service.data==candidate,"Timeout must restore the previous settings")
	var saved=ConfigFile.new(); assert(saved.load(service.config_path)==OK and saved.get_value("settings","mode")==candidate.mode)
	menu.close(); menu.open(); assert(menu.draft==service.data,"Unconfirmed changes must not reappear on reopening")
	var image=Image.create(1024,512,false,Image.FORMAT_RGBA8); image.fill(Color.RED)
	var file: String="user://quality53.png"; assert(image.save_png(file)==OK)
	var quality=load("res://src/texture_quality.gd"); quality.apply(0); var texture=quality.create(image,file); var identity: int=texture.get_instance_id()
	assert(texture.get_width()==1024); quality.apply(512); assert(texture.get_width()==512 and texture.get_height()==256 and texture.get_instance_id()==identity)
	quality.apply(0); assert(texture.get_width()==1024 and texture.get_instance_id()==identity,"Original quality must be restorable without replacing material references")
	service.apply(original,false); TranslationServer.set_locale("it")
	assert(TranslationServer.translate("GIOCA")=="GIOCA" and TranslationServer.translate("Qualità ricezione 84%")=="Qualità ricezione 84%","Italian must not fall back to the English catalogue")
	assert(TranslationServer.translate("PLAYER PROFILE")=="PROFILO GIOCATORE")
	var invalid=service.DEFAULTS.duplicate(); invalid.language="bad"; invalid.textures=123; invalid.scale=-2.0; invalid.mode=99
	var safe: Dictionary=service.sanitize(invalid); assert(safe.language=="it" and safe.textures==0 and safe.scale==.5 and safe.mode==2)
	FileAccess.open("res://docs/settings53-report.json",FileAccess.WRITE).store_string(JSON.stringify({"saved_and_reloaded":true,"native_monitor_cases":["1920x1080","2560x1440","3840x2160","3440x1440"],"low_ultra_presets_verified":true,"fsr_ssil_ssr_exposure_shadow_distance_verified":true,"viewport_verified":true,"environment_nodes":environments,"shadow_lights":lights,"crowd_groups":crowds,"texture_dimensions":[1024,512,1024],"texture_reference_preserved":true,"controller_footer_both_pages":true,"video_timeout_rollback":true,"translations":load("res://src/localization.gd").catalogue.size(),"english_hud_dynamic":true,"italian_roundtrip":true,"role_ids_preserved":true,"physics_and_rotations_unchanged":true,"physics_hz":physics},"  "))
	print("SETTINGS53 PASS persistence / actual renderer properties / texture downscale+restore / translations+IDs / controller / display rollback / unchanged physics")
	g.free(); quit()
