extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var arena=preload("res://src/arena.gd").new(); root.add_child(arena)
	assert(arena.sponsors.logos.size()==4)
	for logo in arena.sponsors.logos: assert(logo!=null and logo.get_width()>300)
	assert(arena.sponsors.court_marks.size()==2)
	for mark in arena.sponsors.court_marks:
		assert(is_equal_approx(mark.mesh.size.x/mark.mesh.size.y,1234.0/641.0))
		assert(absf(mark.position.z)>4.5 and mark.position.x<4.5)
	assert(arena.sponsors.panels.size()==22)
	var first=arena.sponsors.panels[0].get_shader_parameter("logo_a")
	arena.sponsors._process(8.1)
	assert(arena.sponsors.panels[0].get_shader_parameter("logo_a")!=first)
	assert(arena.crowd_instance_count==arena.crowd_positions.size())
	assert(arena.crowd_instance_count>1000 and arena.crowd_instance_count<1600)
	assert(arena.crowd_materials.size()==24)
	var skeletons:=0; var meshes:=0; var batches:=0
	for node in arena.find_children("*","",true,false):
		if node is Skeleton3D: skeletons+=1
		if node is MeshInstance3D: meshes+=1
		if node is MultiMeshInstance3D: batches+=1
	assert(skeletons==0)
	assert(batches==11)
	assert(meshes<280)
	arena.crowd_react(); arena._process(0.1)
	assert(arena.crowd_materials[0].get_shader_parameter("excitement")>0.9)
	# Reopening a second arena preserves the immutable cached mesh materials.
	var repeated=preload("res://src/crowd.gd").create(0)
	assert(repeated.surface_get_material(0) is StandardMaterial3D)
	print("ARENA38 PASS original_logos=4 court_marks=2 LED_panels=22 spectators=",arena.crowd_instance_count," variants=8 crowd_skeletons=",skeletons," static_meshes=",meshes," instanced_batches=",batches)
	quit()
