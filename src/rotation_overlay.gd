extends Control
const Model=preload("res://src/rotation_model.gd")
var game

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE

func _process(_dt: float) -> void:
	visible=game.started and (game.debug_visible or "--rotation-debug" in OS.get_cmdline_user_args())
	if visible: queue_redraw()

func _draw() -> void:
	var font:=ThemeDB.fallback_font
	for index in 12:
		var team:=int(index/6)
		var state:=Model.state(index,game.rotations[team],team==game.server)
		var player=game.players[index]
		var at: Vector2=game.camera.unproject_position(player.position+Vector3.UP*2.35)
		var text: String=state.player_id+" Z"+str(state.rotation_slot)+(" FRONT" if state.is_front_row else " BACK")+(" SERVER" if state.is_server else "")
		draw_string(font,at-Vector2(70,0),text,HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("ffe4a0"))
		var target: Vector2=game.camera.unproject_position(player.target+Vector3.UP*0.03)
		draw_circle(target,4,Color("67e9bc"))
		if game.phase=="SERVE":
			for foot in game.rotation_context.feet(game,index): draw_circle(game.camera.unproject_position(foot),2,Color("67e9bc"))
	var snap: Dictionary=game.rotation_context.service_snapshot
	if not snap.is_empty():
		draw_string(font,Vector2(24,size.y-54),"SERVICE FEET: "+("LEGAL" if snap.legal else "OVERLAP")+" · R"+str(snap.rotation+1)+" · "+game.phase,HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("ffe4a0"))
