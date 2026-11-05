extends "res://tools/Preview-Motion41.gd"
var pending:=false
func setup():
	super.setup();root.position=Vector2i(19000,19000)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
func begin_stage(next: int): stage=next
func _process(_dt: float) -> bool:
	if not ready or pending:return false
	if stage>=6:quit();return false
	var action: String="dive" if stage<4 else "receive"
	var names: Array=["dive_v26_02","dive_v26_04"] if stage<4 else ["receive_left_step","receive_right_step"]
	var offset: float=[0,.3,.65,1.0,0,.3][stage]
	for side in 2:
		var p=actors[side];p.motion_lock=0;p.contact_scheduled=false;p.looping=true
		p.select_variant(action,names[side]);p.play(action);p.blend_left=0;p.reach_weight=0
		p.animation_time=p.clips[action].contact_time+offset;p.apply_pose(1.0/60)
		cameras[side].position=Vector3(3.5,2.1,5);cameras[side].look_at(Vector3(0,.9,.1))
		balls[side].hide()
	curtain.color.a=0;title.text=str(names)+" +"+str(offset)
	pending=true;RenderingServer.frame_post_draw.connect(capture77,CONNECT_ONE_SHOT)
	return false
func capture77():
	root.get_texture().get_image().save_png("res://.runtime/defense77/source-%d.png"%stage)
	stage+=1;pending=false
