extends SceneTree

class PointGame extends Node:
	var started:=true
	var receive_feedback_left:=0.0
	var camera_mode:=0
	var team_names:=["Allianz Milano","Cisterna Volley"]
	var scores:=[4,3]
	var sets:=[0,0]
	var match_best_of:=5
	var demo:=false
	var gallery:=false
	var feedback_left:=2.0
	var feedback:="Allianz Milano"
	var point_reason:="PALLA A TERRA"
	var phase:="POINT"
	var debug_visible:=false
	var paused:=false
	func pad() -> int: return -1
	func human_wall() -> bool: return false

class DrawProbe extends "res://src/hud.gd":
	var central_panels:=0
	var central_labels: Array[String]=[]
	var scoreboard_labels: Array[String]=[]
	func panel(rect: Rect2, _color: Color=INK) -> void:
		if is_equal_approx(rect.size.x,436.0): central_panels+=1
	func centered(_y: float, value: String, _px: int=18, _color: Color=WHITE) -> void:
		central_labels.append(value)
	func text(_at: Vector2, value: String, _px: int=16, _color: Color=WHITE) -> void:
		scoreboard_labels.append(value)
	func clear_probe() -> void:
		central_panels=0; central_labels.clear(); scoreboard_labels.clear()

func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game:=PointGame.new(); root.add_child(game)
	var hud:=DrawProbe.new(); hud.game=game; hud.size=Vector2(1440,810); root.add_child(hud)
	await process_frame; await process_frame
	assert(not hud.point_result_visible())
	assert(hud.central_panels==0 and hud.central_labels.is_empty(),"Ordinary point must render no central announcement")
	assert("Allianz Milano" in hud.scoreboard_labels and "Cisterna Volley" in hud.scoreboard_labels,"Scoreboard remains visible")
	game.point_reason="SET Allianz Milano"; hud.clear_probe(); hud.queue_redraw()
	await process_frame; await process_frame
	assert(hud.point_result_visible() and hud.central_panels>0,"Set result is a separate retained announcement")
	assert(game.point_reason in hud.central_labels and not game.feedback in hud.central_labels,"Results must use the actual result, never stale gameplay feedback")
	game.point_reason="VITTORIA Allianz Milano"; hud.clear_probe(); hud.queue_redraw()
	await process_frame; await process_frame
	assert(hud.point_result_visible() and "VITTORIA Allianz Milano" in hud.central_labels)
	game.phase="SERVE"
	assert(not hud.point_result_visible(),"Previous set result cannot survive into next rally")
	hud.set_process(false); hud.hide()
	print("POINT HUD39 PASS ordinary_point_no_overlay scoreboard_retained distinct_set_match_results")
	quit()
