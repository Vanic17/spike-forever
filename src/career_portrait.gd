extends SubViewportContainer
## The selected in-game appearance, rendered once. No remote portrait required.
var game
var identity: Dictionary
var kit: Dictionary
func _ready():
	custom_minimum_size=Vector2(260,240); stretch=true; mouse_filter=Control.MOUSE_FILTER_IGNORE
	var viewport=SubViewport.new(); viewport.size=Vector2i(640,560); viewport.own_world_3d=true; viewport.transparent_bg=true; viewport.msaa_3d=Viewport.MSAA_2X; add_child(viewport)
	var world=Node3D.new(); viewport.add_child(world)
	var environment=WorldEnvironment.new(); var env=Environment.new(); env.background_mode=Environment.BG_COLOR; env.background_color=Color("142740"); env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR; env.ambient_light_color=Color("d9e5fa"); env.ambient_light_energy=.75; environment.environment=env; world.add_child(environment)
	var light=DirectionalLight3D.new(); light.rotation_degrees=Vector3(-25,-35,0); light.light_energy=1.7; world.add_child(light)
	var actor=load("res://src/avatar.gd").new(); world.add_child(actor); actor.setup(game.clips,0,int(identity.get("jersey_number",1)),game.models)
	actor.set_roster_identity(identity,identity,kit,kit); actor.set_process(false); actor.render_at_draw=false; actor.indicator.hide(); actor.play("relaxed",1,true); actor.apply_pose(0)
	var head=actor.skeleton.find_bone("Head"); var focus=Vector3(0,1.25,0)
	if head>=0: focus=actor.skeleton.to_global(actor.skeleton.get_bone_global_pose(head).origin)+Vector3(0,-.16,0)
	var camera=Camera3D.new(); camera.position=focus+Vector3(.04,.04,1.55); world.add_child(camera); camera.fov=34; camera.look_at(focus); camera.current=true
	await get_tree().process_frame; await get_tree().process_frame
	if is_instance_valid(viewport): viewport.render_target_update_mode=SubViewport.UPDATE_ONCE
