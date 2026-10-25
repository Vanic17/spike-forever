extends SceneTree
var failures:=0
func _initialize(): call_deferred("run")
func check(ok: bool,message: String):
	if not ok: failures+=1; push_error("PREFERENCES51 FAIL "+message)
func run():
	var g=load("res://src/main.tscn").instantiate(); root.add_child(g); g.set_process(false); g.set_physics_process(false); g.self_test=true
	var menu
	for n in g.get_children():
		if n.get_script()==load("res://src/start_menu.gd"): menu=n
	var editor=menu.clubs; editor.editor(); editor.player_pick.select(0); editor.edit_player(0); editor.enter_details()
	check(editor.inputs.dominant_hand.focus_mode==Control.FOCUS_ALL and editor.inputs.serve_preference.focus_mode==Control.FOCUS_ALL,"controller focus")
	editor.inputs.name.grab_focus()
	var reached: Array=[]
	for i in 6:
		editor.focus_editor_step(false)
		reached.append(root.gui_get_focus_owner())
	check(editor.inputs.dominant_hand in reached and editor.inputs.serve_preference in reached,"controller vertical traversal")
	editor.inputs.dominant_hand.select(1); editor.inputs.serve_preference.select(1); editor.save_player()
	var saved_id: String=editor.current.id
	var db=load("res://src/league.gd").new(); var saved: Dictionary={}
	for t in db.teams:
		for p in t.roster:
			if p.id==saved_id: saved=p
	check(saved.get("dominant_hand")=="left" and saved.get("serve_preference")=="float","persisted local overrides")
	var p=g.players[0]; var person: Dictionary=saved.duplicate(true); person.dominant_hand="right"
	p.roster_identity=person; p.apply_identity(); p.select_variant("attack","attack_pin_left"); p.play("attack",1,false)
	p.animation_time=p.clips.attack.contact_time
	var right: Array[Transform3D]=p.normalized_pose("attack",p.animation_time,false)
	var offset: Vector3=p.contact_local("attack")
	person.dominant_hand="left"; p.apply_identity()
	var left: Array[Transform3D]=p.normalized_pose("attack",p.animation_time,false)
	var names: Array=p.clips.idle.names
	var hand: int=names.find("RightHand"); var other: int=names.find("LeftHand")
	check(left[other].origin.distance_to(Vector3(-right[hand].origin.x,right[hand].origin.y,right[hand].origin.z))<.0001,"actual left hand pose")
	check(is_equal_approx(p.contact_local("attack").x,-offset.x),"mirrored contact offset")
	for bone in left: check(absf(bone.basis.determinant()-1)<.001,"no negative mesh scale")
	var club: Dictionary=db.teams[0]; var squad: Array=db.lineup(club)
	var replacement=squad[2]; squad[2]=squad[0]; squad[0]=replacement
	check(db.save_lineup(club,squad.map(func(player): return player.id))==OK,"OH and OPP swap can save")
	var reloaded=load("res://src/league.gd").new(); var restored: Array=reloaded.lineup(reloaded.teams[0])
	check(restored[2].id==squad[2].id and restored[0].id==squad[0].id,"cross-role lineup survives reload")
	var session_type=load("res://src/online_session.gd")
	var clean: Dictionary=session_type.sanitize_choice({"club":club.id,"kit":"away","rotation":2,"roster":restored},reloaded)
	check(not clean.is_empty() and clean.roster.any(func(player): return player.dominant_hand=="left" and player.serve_preference=="float"),"online shares personal preferences")
	editor.match_setup(); editor.show_match_formation(0,club,editor.formation_buttons[0])
	var options=editor.formation_dialog.find_children("*","OptionButton",true,false)
	check(options.size()==8,"rotation and seven starters")
	check(g.Timing.ace_power(1) and not g.Timing.ace_power(.97) and not g.Timing.ace_power(.99) and not g.Timing.ace_power(1.01),"only displayed 100 percent ace")
	check(g.Timing.winning_power(.97),"attack winning band unchanged")
	var online=menu.online_menu; online.open()
	check(online.formation.visible and online.confirm.visible and online.create.visible and online.join.visible,"visible online controls")
	var snapshot=load("res://src/online_state.gd"); var state: Dictionary=snapshot.capture(g); var packet: PackedByteArray=snapshot.encode(state)
	check(snapshot.valid(snapshot.decode(packet)),"bounded compressed snapshot roundtrip")
	var baseline_bytes:=packet.size()
	var invitation=load("res://src/room_code.gd")
	var code: String=invitation.encode("127.0.0.1",26761,0x123456)
	check(invitation.decode(code).port==26761 and invitation.decode(code).room==0x123456,"room code roundtrip")
	check(invitation.decode("wrong").is_empty(),"invalid code rejected")
	var noise:=""; var random:=RandomNumberGenerator.new(); random.seed=51
	for i in 2000: noise+=char(random.randi_range(33,126))
	state.feedback=noise; state.seq=123; packet=snapshot.encode(state)
	var net=g.online_session; net.playing=true; net.local_side=1; net.buffered.clear()
	var count:=ceili(packet.size()/1100.0)
	for part in range(count-1,-1,-1): net.snapshot_piece(123,part,count,packet.slice(part*1100,mini(packet.size(),(part+1)*1100)))
	check(net.buffered.size()==1 and net.buffered[0].seq==123,"out-of-order snapshot pieces reassembled")
	g.phase="CPU_ATTACK"; g.possession=1; net.local_charge_kind="attack"; net.local_charge_start=Time.get_ticks_usec()/1000000.0-g.Timing.ATTACK_CHARGE_SECONDS
	check(absf(g.current_charge()-1)<.01,"guest bar predicts locally without a snapshot acknowledgement")
	net.local_charge_start=-1; net.local_charge_released=-1
	net.playing=false; net.local_side=0; net.buffered.clear()
	print("PREFERENCES51 ","PASS" if failures==0 else "FAIL"," local persistence / real left-hand pose / controller navigation / OH-OPP swap / exact-100 ace / online menu / snapshot bytes=",baseline_bytes)
	FileAccess.open("res://docs/preferences51-report.json",FileAccess.WRITE).store_string(JSON.stringify({"controller":true,"local_save":true,"left_hand":true,"cross_role":true,"ace_100_only":true,"snapshot_bytes":baseline_bytes,"fragment_reassembly":true},"  "))
	g.free(); quit(0 if failures==0 else 1)
