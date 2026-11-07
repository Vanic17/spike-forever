extends SceneTree
var frames:=0
func _initialize():call_deferred("run")
func run():
	root.size=Vector2i(1280,720);root.position=Vector2i(19000,19000)
	var scene:=Node3D.new();root.add_child(scene)
	var camera:=Camera3D.new();scene.add_child(camera);camera.position=Vector3(0,1.35,2.3);camera.look_at(Vector3(0,1.1,0));camera.fov=38
	var light:=DirectionalLight3D.new();scene.add_child(light);light.rotation_degrees=Vector3(-35,-25,0)
	var env:=WorldEnvironment.new();env.environment=Environment.new();env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color(.12,.15,.20);env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_color=Color.WHITE;env.environment.ambient_light_energy=.7;scene.add_child(env)
	for side in [-1,1]:
		var instance:=MeshInstance3D.new();instance.mesh=load("res://src/crowd.gd").create(4) if side<0 else load("res://assets/art/quality89/crowd/v04_l3.res");scene.add_child(instance);instance.position.x=side*.4
		for s in instance.mesh.get_surface_count():
			var m:=StandardMaterial3D.new();m.albedo_color=Color(.8,.8,.8) if s<3 else Color(.2,.7,.9);m.cull_mode=BaseMaterial3D.CULL_DISABLED;instance.set_surface_override_material(s,m)
	if "--heads" in OS.get_cmdline_user_args():
		for node in scene.get_children():
			if node is MeshInstance3D:node.queue_free()
		camera.position=Vector3(0,1.72,1.25);camera.look_at(Vector3(0,1.72,0));camera.fov=50
		for level in 4:
			var source: ArrayMesh=load("res://assets/art/quality89/head%d.res"%level) if level<3 else load("res://assets/art/athlete88/head.res")
			var a=source.surface_get_arrays(0);a[Mesh.ARRAY_BONES]=null;a[Mesh.ARRAY_WEIGHTS]=null
			var instance:=MeshInstance3D.new();instance.mesh=ArrayMesh.new();instance.mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,a);scene.add_child(instance);instance.position.x=(level-1.5)*.27
			var m:=StandardMaterial3D.new();m.albedo_color=Color(.8,.8,.8);m.cull_mode=BaseMaterial3D.CULL_DISABLED;instance.material_override=m
func _process(_dt):
	frames+=1
	if frames==20:
		await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://.runtime/crowd89-clay.png");quit()
	return false
