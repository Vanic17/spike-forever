extends SceneTree
class Adapter extends Node:
	var active:=true
	var manual_available:=true
	var controlled_index:=0
	var recommended_position:=Vector3(-2.4,0,4.8)
class OverlayState extends Node:
	var active:=false
class MatchHost extends Node3D:
	var legend_match=Adapter.new()
	var started:=true
	var paused:=false
	var match_finished:=false
	var phase:="RECEIVE"
	var replay=OverlayState.new()
	var substitution_scene=OverlayState.new()
	var players: Array=[]
var checks:=0
var failures: Array=[]
func _initialize(): call_deferred("run")
func check(ok: bool,message: String):
	checks+=1
	if not ok:failures.append(message);push_error("LEGEND GUIDE73 "+message)
func run():
	var game=MatchHost.new();root.add_child(game)
	game.add_child(game.legend_match);game.add_child(game.replay);game.add_child(game.substitution_scene)
	var player=Node3D.new();game.add_child(player);player.position=Vector3(3,0,6);game.players.append(player)
	var original: Vector3=player.position
	var guide=load("res://src/legend_position_guide.gd").new();guide.game=game;game.add_child(guide);guide.set_process(false)
	guide.sync_from_game()
	check(guide.visible,"guide appears during an active manual rally")
	check(guide.position.is_equal_approx(Vector3(-2.4,guide.FLOOR_HEIGHT,4.8)),"guide uses the exact shared AI target projected onto the floor")
	check(player.position==original,"guide never moves the controlled athlete")
	var mesh=guide.ring.mesh;var material=guide.ring.material_override
	var visibility_events: Array=[0]
	guide.visibility_changed.connect(func(): visibility_events[0]+=1)
	check(material.transparency==BaseMaterial3D.TRANSPARENCY_ALPHA and material.vertex_color_use_as_albedo,"guide has vertex alpha transparency")
	check(guide.ring.cast_shadow==GeometryInstance3D.SHADOW_CASTING_SETTING_OFF,"guide casts no shadow")
	for frame in 600:
		game.legend_match.recommended_position=Vector3(sin(frame*.1)*4,2.5,1.4+frame*.01)
		guide.sync_from_game()
	check(guide.ring.mesh==mesh and guide.ring.material_override==material and guide.get_child_count()==1,"guide reuses one mesh and one material through all frames")
	check(player.position==original,"600 target updates leave actual movement untouched")
	check(visibility_events[0]==0,"continuous target updates do not toggle render visibility or flicker")
	game.paused=true;guide.sync_from_game();check(not guide.visible,"guide hides while paused");game.paused=false
	game.legend_match.manual_available=false;guide.sync_from_game();check(not guide.visible,"guide hides while the athlete is on the bench");game.legend_match.manual_available=true
	game.phase="POINT";guide.sync_from_game();check(not guide.visible,"guide hides between points");game.phase="ATTACK"
	game.replay.active=true;guide.sync_from_game();check(not guide.visible,"guide hides during replay");game.replay.active=false
	game.substitution_scene.active=true;guide.sync_from_game();check(not guide.visible,"guide hides during substitutions");game.substitution_scene.active=false
	game.legend_match.recommended_position=Vector3(INF,0,1);guide.sync_from_game();check(not guide.visible,"invalid target stays hidden")
	game.legend_match.recommended_position=Vector3(3.5,0,1.1);guide.sync_from_game();check(guide.visible and guide.position.is_equal_approx(Vector3(3.5,guide.FLOOR_HEIGHT,1.1)),"guide resumes at the new current tactical target")
	game.legend_match.active=false;guide.sync_from_game();check(not guide.visible,"guide is absent in exhibition and other modes")
	var report: Dictionary={"checks":checks,"failures":failures,"radius":guide.RADIUS,"visual_only":true,"reuses_geometry":true}
	FileAccess.open("res://docs/legend73-guide.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("LEGEND GUIDE73 ",JSON.stringify(report))
	game.free();quit(0 if failures.is_empty() else 1)
