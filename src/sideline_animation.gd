extends Node
## Original cinematic performances, baked once and evaluated natively at 30 Hz.
static var library: AnimationLibrary
var player: AnimationPlayer
var idle:="bench_idle_l"
var actor
static func bank() -> AnimationLibrary:
	if library==null: library=load("res://assets/art/sideline69/animations.res")
	return library
func setup(target,idle_clip: String,offset: float=0.0) -> void:
	actor=target; idle=idle_clip; actor.visual_root.name="Visual"; actor.skeleton.name="Rig"
	player=AnimationPlayer.new(); add_child(player); player.root_node=NodePath("../..")
	player.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	player.add_animation_library("",bank())
	player.animation_finished.connect(func(_name): play(idle,.24))
	play(idle,0); player.advance(offset)
func play(clip: String,blend: float=.20,speed: float=1.0) -> void:
	player.play(clip,blend,speed); player.advance(0)
func advance(dt: float) -> void: player.advance(dt)
static func sample(rig,name: String,time: float) -> Array[Transform3D]:
	var animation: Animation=bank().get_animation(name)
	time=fposmod(time,animation.length) if animation.loop_mode==Animation.LOOP_LINEAR else clampf(time,0,animation.length)
	var result: Array[Transform3D]=[]
	for i in rig.names.size(): result.append(Transform3D(Basis(animation.rotation_track_interpolate(i*2+1,time)),animation.position_track_interpolate(i*2,time)))
	return result
