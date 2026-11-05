extends "res://tools/Preview-Motion41.gd"
const VARIANTS:=["receive_slide77","receive_slide_right77","dive_slide77","dive_slide_right77","defense_miss77","defense_miss_right77"]
const SOURCES:=["receive_left_step","receive_right_step","dive_v26_02","dive_v26_04","dive_v26_02","dive_v26_04"]
var capture_frame:=0
var contacts: Dictionary={}
var capture_pending:=false
func setup() -> void:
	super.setup()
	root.position=Vector2i(19000,19000)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.runtime/defense77-frames"))
func begin_stage(next: int) -> void:
	stage=next; clock=0
	if stage>=6: return
	var action: String="dive" if stage>=2 else "receive"
	for side in 2:
		var p=actors[side]
		p.motion_lock=0; p.contact_scheduled=false; p.reach_weight=0
		p.select_variant(action,SOURCES[stage] if side==0 else VARIANTS[stage]); p.play(action,1,false)
		p.blend_left=0; p.foot_planted=[false,false]; p.foot_weights=[0.0,0.0]
	title.text="DIFESE / "+["BAGHER LATERALE SX","BAGHER LATERALE DX","RECUPERO SENZA CAPRIOLA SX","RECUPERO SENZA CAPRIOLA DX","TENTATIVO ESTREMO SX","TENTATIVO ESTREMO DX"][stage]
	details.text="Sinistra: gesto di base / Destra: appoggio basso dal riferimento. Contatto sincronizzato e risalita senza capriola. Ultimi due esempi: tentativi falliti."
func render_frame(time: float, dt: float) -> void:
	if stage>=6: return
	var action: String="dive" if stage>=2 else "receive"
	var source=game.clips[SOURCES[stage]]
	var at_contact:=Motion.normalized(source,source.contact_time)
	var right: int=source.names.find("RightHand"); var left: int=source.names.find("LeftHand")
	var local_goal: Vector3=at_contact[right].origin+Vector3(0,0,.085) if stage>=2 else (at_contact[right].origin+at_contact[left].origin)*.5+Vector3(0,.07,0)
	var goal: Vector3=source.root_motion(source.contact_time)+local_goal
	var travel: Vector3=source.root_motion(time)
	var incoming: Vector3=goal+Vector3(0,2,2)*maxf(0,source.contact_time-time)
	if time>source.contact_time: incoming=goal+Vector3(0,2,-2)*(time-source.contact_time)
	for side in 2:
		var p=actors[side]; p.position=travel; p.animation_time=time
		var own_goal: Vector3=source.root_motion(source.contact_time)+game.clips[SOURCES[stage] if side==0 else VARIANTS[stage]].contact_offset
		p.reach_action=action; p.reach_target=own_goal
		p.reach_weight=smoothstep(source.contact_time-.14,source.contact_time-.015,time)*(1-smoothstep(source.contact_time+.025,source.contact_time+.15,time))
		var own_ball:=incoming+(own_goal-goal)
		if stage>=4: own_ball+=Vector3(1.5,0,0)
		p.look_target=own_ball; p.apply_pose(dt); balls[side].position=own_ball
		cameras[side].position=travel+Vector3(3.5,2.1,5)
		cameras[side].look_at(travel+Vector3(0,.9,.1))
		assert(p.pose_tree.initialized)
func _process(_delta: float) -> bool:
	if not ready: return false
	if capture_pending: return false
	if stage>=6:
		FileAccess.open("res://docs/defense77-preview.json",FileAccess.WRITE).store_string(JSON.stringify({"pass":true,"frames":capture_frame,"fps":60,"variants":VARIANTS,"contacts":contacts,"method":"production Avatar, native AnimationTree, source root travel and final IK"},"  "))
		quit(); return false
	var source=game.clips[SOURCES[stage]]
	render_frame(minf(clock,source.duration),1.0/60)
	curtain.color.a=1-smoothstep(0,.12,clock)
	capture_pending=true
	RenderingServer.frame_post_draw.connect(capture,CONNECT_ONE_SHOT)
	return false
func capture() -> void:
	var source=game.clips[SOURCES[stage]]
	var image: Image=root.get_texture().get_image()
	image.save_jpg("res://.runtime/defense77-frames/%05d.jpg"%capture_frame,.87)
	if absf(clock-source.contact_time)<1.0/60 and not contacts.has(stage):
		var file: String="res://docs/defense77-"+VARIANTS[stage]+".png"
		image.save_png(file); contacts[stage]=file
	capture_frame+=1; clock+=1.0/60
	if clock>source.duration+.35: begin_stage(stage+1)
	capture_pending=false
