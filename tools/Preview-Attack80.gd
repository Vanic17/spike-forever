extends "res://tools/Preview-Motion41.gd"
const VARIANTS:=["attack_middle_style80","attack_middle_style_right80","attack_middle_style80","attack_middle_style_right80"]
const SOURCES:=["attack_pin_left","attack_pin_right","attack_pin_left","attack_pin_right"]
var capture_frame:=0
var pending:=false
var contacts: Dictionary={}
func setup():
	super.setup();root.position=Vector2i(19000,19000)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.runtime/attack80-frames"))
func begin_stage(next: int):
	stage=next;clock=-.75
	if stage>=4:return
	for side in 2:
		var p=actors[side];p.motion_lock=0;p.contact_scheduled=false;p.looping=true
		p.left_handed=stage>=2
		p.select_variant("attack",SOURCES[stage] if side==0 else VARIANTS[stage])
		p.play("run",1.3,true);p.blend_left=0;p.reach_weight=0
		p.pin_reference_load=0 if side==0 else 1
		p.foot_planted=[false,false];p.foot_weights=[0.0,0.0]
	title.text="ATTACCO / "+("MANCINO" if stage>=2 else "DESTRO")+" / "+("ZONA 2" if stage%2 else "ZONA 4 / PIPE")
	details.text="Sinistra: attacco precedente / Destra: variante del centrale adattata alla rincorsa laterale."
func _process(_dt: float) -> bool:
	if not ready or pending:return false
	if stage>=4:
		FileAccess.open("res://docs/attack80-preview.json",FileAccess.WRITE).store_string(JSON.stringify({"pass":true,"frames":capture_frame,"fps":60,"contacts":contacts,"variants":VARIANTS,"hands":["right","left"],"method":"production Avatar / native AnimationTree / real running feet / authored upper-body anticipation"},"  "))
		quit();return false
	var source=game.clips[SOURCES[stage]]
	for side in 2:
		var p=actors[side];p.velocity=Vector3(0,0,4.2) if clock<0 else Vector3.ZERO
		p.intent.task="approach"
		if clock>=0 and p.clip_name!="attack":p.play("attack",1,false)
		p.tick(1.0/60,false,false)
		if clock<0:
			p.position=Vector3(0,0,clock*4.2)
			p.pin_reference_load=0 if side==0 else 1
		else:
			p.animation_time=minf(clock,source.duration);p.position=p.action_root_motion("attack",p.animation_time)
		var contact: Vector3=p.action_root_motion("attack",source.contact_time)+p.contact_local("attack")
		var ball: Vector3=contact+Vector3(0,2,2)*maxf(0,source.contact_time-clock)
		if clock>source.contact_time:ball=contact+Vector3(0,-2,2)*(clock-source.contact_time)
		p.reach_action="attack";p.reach_target=contact
		p.reach_weight=smoothstep(source.contact_time-.14,source.contact_time-.015,clock)*(1-smoothstep(source.contact_time+.025,source.contact_time+.15,clock))
		p.look_target=ball;p.apply_pose(1.0/60);balls[side].position=ball
		cameras[side].position=p.position+Vector3(3.5,2.6,5);cameras[side].look_at(p.position+Vector3(0,1.5,.1))
	curtain.color.a=1-smoothstep(-.75,-.60,clock)
	pending=true;RenderingServer.frame_post_draw.connect(capture78,CONNECT_ONE_SHOT)
	return false
func capture78():
	var source=game.clips[SOURCES[stage]];var image=root.get_texture().get_image()
	image.save_jpg("res://.runtime/attack80-frames/%05d.jpg"%capture_frame,.87)
	if absf(clock-source.contact_time)<1.0/60 and not contacts.has(stage):
		var path: String="res://docs/attack80-contact-%d.png"%stage
		image.save_png(path);contacts[stage]=path
	capture_frame+=1;clock+=1.0/60
	if clock>source.duration+.25:begin_stage(stage+1)
	pending=false
