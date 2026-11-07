extends SceneTree
func _initialize():call_deferred("run")
func run():
	root.position=Vector2i(19000,19000);root.size=Vector2i(1024,1024)
	var world:=Node3D.new();root.add_child(world)
	var document=ClassDB.instantiate("FBXDocument");var state=ClassDB.instantiate("FBXState");assert(document.append_from_file("res://assets/art/athlete88/source/Head.fbx",state)==OK)
	var scan=document.generate_scene(state);world.add_child(scan);scan.scale=Vector3.ONE*30
	var material:=StandardMaterial3D.new();material.albedo_texture=ImageTexture.create_from_image(Image.load_from_file("res://assets/art/athlete88/source/lambertian.jpg"));material.roughness=.65;material.cull_mode=BaseMaterial3D.CULL_DISABLED
	for m in scan.find_children("*","MeshInstance3D",true,false):m.material_override=material
	var camera:=Camera3D.new();world.add_child(camera);camera.position=Vector3(0,.15,.65);camera.look_at(Vector3(0,.15,0));camera.fov=35
	var light:=DirectionalLight3D.new();world.add_child(light);light.rotation_degrees=Vector3(-25,-30,0)
	var environment:=WorldEnvironment.new();world.add_child(environment);environment.environment=Environment.new();environment.environment.background_mode=Environment.BG_COLOR;environment.environment.background_color=Color("333333");environment.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;environment.environment.ambient_light_color=Color.WHITE;environment.environment.ambient_light_energy=.4
	for i in 12:await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.runtime/scan88-preview.png");print("SCAN88 PREVIEW PASS");quit()
