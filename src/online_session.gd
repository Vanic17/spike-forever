extends Node
## Two human teams, one authoritative simulation. ENet transport and invite
## format follow Volley Rivals; a code is an endpoint, not a hosted relay.
const Code=preload("res://src/room_code.gd")
const State=preload("res://src/online_state.gd")
const PROTOCOL="SF066"
const PORT=26761
var game
var menu
var active:=false
var playing:=false
var closing:=false
var local_side:=0
var guest:=0
var generation:=0
var requested_generation:=0
var choices: Array=[{},{}]
var ready_flags: Array=[false,false]
var best_of:=5
var points:=25
var use_player_stats:=false
var use_fatigue:=true
var local_charge_release_seen:=-1.0
var inputs: Array=[{},{}]
var sequence:=0
var last_sequence: Array=[-1,-1]
var public_ip:=""
var local_ip:=""
var room_code:=""
var info:="Crea una partita oppure inserisci il codice dell'host."
var http: HTTPRequest
var mapper: Thread
var upnp: UPNP
var mapping_result: Dictionary={}
var test_mode:=false
var port:=PORT
var join_elapsed:=0.0
var packet_age:=0.0
var send_clock:=0.0
var buffered: Array=[]
var incoming_chunks: Dictionary={}
var last_contact:=0
var last_scores: Array=[0,0]
var last_receive:=0
var snapshot_max_bytes:=0
var local_charge_start:=-1.0
var local_charge_button:=""
var local_charge_kind:=""
var local_charge_released:=-1.0
var local_charge_expiry:=0.0

func _ready() -> void:
	multiplayer.peer_disconnected.connect(peer_left)
	multiplayer.peer_connected.connect(func(id): if authority(): verify_join_later(id))
	multiplayer.connected_to_server.connect(connected)
	multiplayer.connection_failed.connect(func(): if active: leave("Connessione non riuscita: verifica codice e raggiungibilità dell'host."))
	multiplayer.server_disconnected.connect(func(): if active: leave("L'host ha chiuso la partita."))
	if multiplayer is SceneMultiplayer: multiplayer.server_relay=false
	http=HTTPRequest.new(); http.timeout=8; add_child(http)
	http.request_completed.connect(public_address)

func authority() -> bool: return active and local_side==0

func verify_join_later(id: int) -> void:
	await get_tree().create_timer(8).timeout
	if authority() and guest!=id and id in multiplayer.get_peers(): multiplayer.multiplayer_peer.disconnect_peer(id,true)

func refresh() -> void:
	if is_instance_valid(menu): menu.refresh()

func host_room() -> Error:
	if active or closing: return ERR_ALREADY_IN_USE
	var peer:=ENetMultiplayerPeer.new()
	var error:=peer.create_server(port,1)
	if error!=OK: info="Porta UDP %d non disponibile: %s"%[port,error_string(error)]; refresh(); return error
	multiplayer.multiplayer_peer=peer
	active=true; playing=false; local_side=0; guest=0; generation=randi_range(1,0xffffff)
	ready_flags=[false,false]; choices=[{},{}]; inputs=[{},{}]; last_sequence=[-1,-1]; sequence=0
	local_ip="127.0.0.1" if test_mode else lan_address()
	public_ip=""; info="Stanza aperta. Preparazione del codice Internet…"; update_code(is_instance_valid(menu) and menu.lan_mode())
	if not test_mode:
		http.request("https://api.ipify.org")
		mapper=Thread.new(); mapper.start(map_port)
	refresh(); return OK

func lan_address() -> String:
	for ip in IP.get_local_addresses():
		if Code.valid_ipv4(ip) and not ip.begins_with("127.") and not ip.begins_with("169.254."): return ip
	return "127.0.0.1"

func map_port() -> void:
	upnp=UPNP.new()
	var result:=upnp.discover(1800,2,"InternetGatewayDevice")
	if result==OK: result=upnp.add_port_mapping(port,port,"Spike Forever","UDP",0)
	mapping_result={"ok":result==OK,"ip":upnp.query_external_address() if result==OK else ""}

func public_address(result: int, response: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if not authority(): return
	var address:=body.get_string_from_utf8().strip_edges()
	if result==HTTPRequest.RESULT_SUCCESS and response==200 and Code.valid_ipv4(address): public_ip=address
	update_code(is_instance_valid(menu) and menu.lan_mode())

func update_code(lan: bool) -> void:
	if not authority(): return
	var endpoint:=local_ip if lan else public_ip
	room_code=Code.encode(endpoint,port,generation)
	if lan: info="Codice per stessa rete / VPN LAN."
	elif room_code.is_empty(): info="Attendo l'indirizzo Internet. Puoi scegliere stessa rete / VPN LAN."
	elif mapping_result.get("ok",false): info="Codice Internet pronto · porta UDP aperta tramite UPnP."
	else: info="Codice Internet pronto · l'host deve essere raggiungibile sulla porta UDP %d (UPnP, inoltro porta o VPN)."%port
	refresh()

func join_room(code: String) -> Error:
	if active or closing: return ERR_ALREADY_IN_USE
	var invitation:=Code.decode(code)
	if invitation.is_empty(): info="Codice non valido: controlla tutte le lettere."; refresh(); return ERR_INVALID_DATA
	var peer:=ENetMultiplayerPeer.new()
	var error:=peer.create_client(invitation.host,invitation.port)
	if error!=OK: info=error_string(error); refresh(); return error
	requested_generation=invitation.room; multiplayer.multiplayer_peer=peer
	room_code=code.strip_edges()
	active=true; local_side=1; playing=false; guest=0; join_elapsed=0; packet_age=0
	inputs=[{},{}]; choices=[{},{}]; ready_flags=[false,false]; last_sequence=[-1,-1]; sequence=0; buffered.clear()
	info="Connessione alla stanza…"; refresh(); return OK

func connected() -> void:
	if active and local_side==1: hello.rpc_id(1,PROTOCOL,requested_generation)

@rpc("any_peer","call_remote","reliable",0)
func hello(protocol: String, room: int) -> void:
	if not authority(): return
	var sender:=multiplayer.get_remote_sender_id()
	if protocol!=PROTOCOL or room!=generation or (guest!=0 and guest!=sender):
		refused.rpc_id(sender,"Versione o codice stanza non corrispondente."); return
	guest=sender; packet_age=0; info="Avversario collegato. Scegliete squadra, divisa e formazione."
	welcome.rpc_id(sender,PROTOCOL,generation); broadcast_lobby()

@rpc("authority","call_remote","reliable",0)
func refused(reason: String) -> void: leave(reason)

@rpc("authority","call_remote","reliable",0)
func welcome(protocol: String, room: int) -> void:
	if local_side!=1 or protocol!=PROTOCOL or room!=requested_generation: return
	guest=multiplayer.get_unique_id(); info="Collegato. Scegli squadra, divisa e formazione."; refresh()

static func sanitize_choice(value: Dictionary, db) -> Dictionary:
	var matches: Array=db.teams.filter(func(t): return t.id==value.get("club",""))
	if matches.size()!=1 or not value.get("roster",[]) is Array or value.roster.size()!=7: return {}
	var club: Dictionary=matches[0]
	var clean: Array=[]; var ids: Array=[]
	for i in 7:
		if not value.roster[i] is Dictionary: return {}
		var p: Dictionary=value.roster[i]
		if not club.roster.any(func(base): return base.id==p.get("id")) or p.get("id") in ids or not db.fits_slot(str(p.get("role","")),i): return {}
		ids.append(p.id)
		var base: Dictionary=club.roster.filter(func(item): return item.id==p.id)[0]
		if not p.get("ratings",{}) is Dictionary: return {}
		var overall=p.get("ratings",{}).get("generale",50)
		if not (overall is float or overall is int) or not is_finite(float(overall)): return {}
		var values: Dictionary={"generale":clampi(int(overall),0,100)}
		for key in preload("res://src/player_stats_gameplay.gd").KEYS:
			var raw=p.get("ratings",{}).get(key,base.ratings.get(key,85))
			if not (raw is float or raw is int) or not is_finite(float(raw)): return {}
			values[key]=clampf(float(raw),0,99)
		clean.append({"id":p.id,"name":str(p.get("name","")).left(48),"jersey_number":clampi(int(p.get("jersey_number",1)),1,99),"role":p.role,"appearance":p.get("appearance",{}).duplicate(true),"ratings":values,"dominant_hand":"left" if p.get("dominant_hand")=="left" else "right","serve_preference":"float" if p.get("serve_preference")=="float" else "jump"})
	var bench: Array=[]
	var provided=value.get("bench",club.roster)
	if not provided is Array or provided.size()>32: return {}
	for raw in provided:
		if not raw is Dictionary: return {}
		var id: String=str(raw.get("id",""))
		if id in ids: continue
		var matches_player: Array=club.roster.filter(func(p): return str(p.id)==id)
		if matches_player.size()!=1 or bench.any(func(p): return str(p.id)==id): return {}
		var p: Dictionary=raw.duplicate(true); var original: Dictionary=matches_player[0]
		if not p.get("ratings",{}) is Dictionary or str(p.get("role",original.role)) not in ["outside_hitter","opposite","middle_blocker","setter","libero"]: return {}
		var values: Dictionary={"generale":clampi(int(p.get("ratings",{}).get("generale",50)),0,100)}
		for key in preload("res://src/player_stats_gameplay.gd").KEYS:
			var rating=p.get("ratings",{}).get(key,original.ratings.get(key,85))
			if not (rating is int or rating is float) or not is_finite(float(rating)): return {}
			values[key]=clampf(float(rating),0,99)
		bench.append({"id":id,"name":str(p.get("name",original.name)).left(48),"jersey_number":clampi(int(p.get("jersey_number",original.jersey_number)),1,99),"role":p.get("role",original.role),"appearance":p.get("appearance",{}).duplicate(true),"ratings":values,"dominant_hand":"left" if p.get("dominant_hand")=="left" else "right","serve_preference":"float" if p.get("serve_preference")=="float" else "jump"})
	return {"club":club.id,"name":club.name,"kit":"away" if value.get("kit")=="away" else "home","rotation":clampi(int(value.get("rotation",0)),0,5),"roster":clean,"bench":bench}

func choose(value: Dictionary, confirmed: bool) -> void:
	if not active or playing: return
	if authority(): set_choice(0,value,confirmed)
	elif guest!=0: submit_choice.rpc_id(1,value,confirmed)

@rpc("any_peer","call_remote","reliable",0)
func submit_choice(value: Dictionary, confirmed: bool) -> void:
	if authority() and multiplayer.get_remote_sender_id()==guest and not playing: set_choice(1,value,confirmed)

func set_choice(side: int, value: Dictionary, confirmed: bool) -> void:
	var db=load("res://src/league.gd").new()
	var clean:=sanitize_choice(value,db)
	if clean.is_empty(): info="Formazione non valida: scegli sette giocatori distinti e ruoli compatibili."; refresh(); return
	choices[side]=clean; ready_flags[side]=confirmed; broadcast_lobby()

func broadcast_lobby() -> void:
	if not authority(): return
	if guest!=0: lobby_state.rpc_id(guest,choices,ready_flags,best_of,points,use_player_stats,use_fatigue)
	refresh()

@rpc("authority","call_remote","reliable",0)
func lobby_state(selected: Array, flags: Array, format: int, target: int, stats_enabled: bool=false,fatigue_enabled: bool=true) -> void:
	if local_side!=1 or selected.size()!=2 or flags.size()!=2: return
	choices=selected; ready_flags=flags; best_of=format; points=target; use_player_stats=stats_enabled; use_fatigue=fatigue_enabled; packet_age=0; refresh()

func start_match() -> bool:
	if not authority() or guest==0 or not ready_flags[0] or not ready_flags[1] or choices[0].is_empty() or choices[1].is_empty(): return false
	begin_match.rpc_id(guest,choices,best_of,points,use_player_stats,use_fatigue)
	begin_local(choices,best_of,points,use_player_stats,use_fatigue)
	return true

@rpc("authority","call_remote","reliable",0)
func begin_match(selected: Array, format: int, target: int, stats_enabled: bool=false,fatigue_enabled: bool=true) -> void:
	if local_side==1 and active: begin_local(selected,format,target,stats_enabled,fatigue_enabled)

func begin_local(selected: Array, format: int, target: int, stats_enabled: bool=false,fatigue_enabled: bool=true) -> void:
	State.setup(game)
	use_player_stats=stats_enabled; game.use_player_stats=stats_enabled; use_fatigue=fatigue_enabled
	choices=selected; best_of=format; points=target; playing=true; buffered.clear(); incoming_chunks.clear(); packet_age=0
	game.match_best_of=format; game.match_points=target; game.camera_mode=0; game.demo=false; game.gallery=false
	var kits=load("res://src/club_kits.gd")
	for side in 2:
		var selection: Dictionary=selected[side]; var squad: Array=selection.roster
		game.team_names[side]=selection.name
		for i in 6: game.players[side*6+i].set_roster_identity(squad[i],squad[6],kits.selection(selection.club,selection.kit),kits.selection(selection.club,selection.kit,true))
	var management_teams: Array=[]
	for choice in selected: management_teams.append({"id":choice.club,"roster":choice.roster+choice.get("bench",[])})
	game.match_management.configure_rosters(management_teams,[selected[0].roster,selected[1].roster],{},{"fatigue":use_fatigue,"injuries":false})
	game.rotations=[selected[0].rotation,selected[1].rotation]; game.scores=[0,0]; game.sets=[0,0]
	game.server=0; game.paused=false; game.match_finished=false; game.started=true
	for wall in game.manual_walls: wall.reset()
	game.reset_rally(); game.set_camera(); last_contact=game.test_contacts; last_scores=[0,0]
	if is_instance_valid(menu): menu.hide(); menu.host.clubs.hide(); menu.host.clubs.music.stop()
	info="Partita online · "+("host" if authority() else "ospite")
	refresh()

func broadcast_management() -> void:
	if authority() and playing and guest!=0: management_state.rpc_id(guest,game.match_management.export_state())

@rpc("authority","call_remote","reliable",0)
func management_state(value: Dictionary) -> void:
	if not playing or local_side!=1: return
	game.match_management.import_state(value)
	if game.match_management.menu.opened:
		game.match_management.menu.incoming=""; game.match_management.menu.zone=0; game.match_management.menu.refresh(); game.match_management.menu.rows[game.match_management.menu.selected_slot].grab_focus()

func request_substitution(slot: int,incoming: String,exceptional: bool=false) -> void:
	if not playing: return
	if authority():
		var reason: String=game.match_management.substitute(0,slot,incoming,exceptional)
		if not reason.is_empty(): game.notice(reason)
	else: substitution_request.rpc_id(1,slot,incoming,exceptional)

@rpc("any_peer","call_remote","reliable",0)
func substitution_request(slot: int,incoming: String,exceptional: bool) -> void:
	if not authority() or not playing or multiplayer.get_remote_sender_id()!=guest: return
	var reason: String=game.match_management.substitute(1,slot,incoming,exceptional)
	if not reason.is_empty(): substitution_reply.rpc_id(guest,reason)

@rpc("authority","call_remote","reliable",0)
func substitution_reply(reason: String) -> void:
	if playing and local_side==1 and game.match_management.menu.opened: game.match_management.menu.status.text=reason

func peer_left(id: int) -> void:
	if active and authority() and id==guest: leave("L'avversario si è disconnesso.")

@rpc("authority","call_remote","reliable",0)
func closed(reason: String) -> void:
	if active: leave(reason,false)

func leave(reason: String="Stanza chiusa", tell: bool=true) -> void:
	if active and authority() and guest!=0 and tell: closed.rpc_id(guest,reason)
	if active and local_side==1 and guest!=0 and tell and multiplayer.multiplayer_peer.get_connection_status()==MultiplayerPeer.CONNECTION_CONNECTED: leave_command.rpc_id(1)
	var transport=multiplayer.multiplayer_peer
	var was_playing:=playing
	active=false; playing=false; guest=0; ready_flags=[false,false]; buffered.clear(); local_charge_start=-1; local_charge_released=-1; info=reason
	http.cancel_request()
	if mapper!=null and mapper.is_started(): mapper.wait_to_finish(); mapper=null
	if upnp!=null and mapping_result.get("ok",false): upnp.delete_port_mapping(port,"UDP")
	upnp=null; mapping_result.clear()
	if not closing:
		closing=true; retire_transport(transport)
	if was_playing: game.return_to_main_menu()
	refresh()

@rpc("any_peer","call_remote","reliable",0)
func leave_command() -> void:
	if authority() and multiplayer.get_remote_sender_id()==guest: leave("L'avversario ha lasciato la stanza.")

func retire_transport(transport) -> void:
	# Keep polling briefly so the reliable end-of-match message leaves ENet's
	# queue before closing the socket; a close in the same tick discards it.
	await get_tree().create_timer(.20).timeout
	if transport!=null: transport.close()
	if multiplayer.multiplayer_peer==transport: multiplayer.multiplayer_peer=OfflineMultiplayerPeer.new()
	closing=false; refresh()

func _exit_tree() -> void:
	if mapper!=null and mapper.is_started(): mapper.wait_to_finish()
	if upnp!=null and mapping_result.get("ok",false): upnp.delete_port_mapping(port,"UDP")

func _process(dt: float) -> void:
	if local_charge_start>=0 and game.paused: local_charge_start+=dt
	if mapper!=null and mapper.is_started() and not mapper.is_alive():
		mapper.wait_to_finish(); mapper=null
		if active and authority():
			if public_ip.is_empty() and Code.valid_ipv4(mapping_result.get("ip","")): public_ip=mapping_result.ip
			update_code(is_instance_valid(menu) and menu.lan_mode())
	if not active: return
	if local_side==1 and guest==0:
		join_elapsed+=dt
		if join_elapsed>12: leave("Host non raggiungibile. Controlla codice, porta UDP o VPN LAN."); return
	if playing:
		packet_age+=dt
		if local_side==1:
			if packet_age>8: leave("Connessione con l'host interrotta."); return
			if game.replay!=null and game.replay.active: packet_age=0
			else: State.render(self,dt)

func _physics_process(dt: float) -> void:
	if not playing or (game.replay!=null and game.replay.active): return
	send_clock+=dt
	if send_clock<1.0/30.0: return
	send_clock=0
	if authority():
		if guest!=0:
			var packet:=State.encode(State.capture(game)); snapshot_max_bytes=maxi(snapshot_max_bytes,packet.size())
			if packet.size()<=1100: snapshot.rpc_id(guest,packet)
			else:
				var count:=ceili(packet.size()/1100.0)
				for part in count: snapshot_piece.rpc_id(guest,Engine.get_physics_frames(),part,count,packet.slice(part*1100,mini(packet.size(),(part+1)*1100)))
	else: send_axes()

@rpc("authority","call_remote","unreliable",1)
func snapshot(packet: PackedByteArray) -> void:
	var value:=State.decode(packet)
	if not playing or local_side!=1 or not State.valid(value): return
	if not buffered.is_empty() and int(value.seq)<=int(buffered[-1].seq): return
	value["arrived"]=Time.get_ticks_msec()/1000.0
	buffered.append(value)
	while buffered.size()>8: buffered.pop_front()
	packet_age=0

@rpc("authority","call_remote","unreliable",1)
func snapshot_piece(seq: int, part: int, total: int, packet: PackedByteArray) -> void:
	if not playing or local_side!=1 or total<2 or total>4 or part<0 or part>=total or packet.size()>1100: return
	if not buffered.is_empty() and seq<=int(buffered[-1].seq): return
	if not incoming_chunks.has(seq):
		var pieces: Array=[]
		for i in total: pieces.append(PackedByteArray())
		incoming_chunks[seq]=pieces
	var pieces: Array=incoming_chunks[seq]
	if pieces.size()!=total: return
	pieces[part]=packet
	if pieces.all(func(piece): return piece.size()>0):
		var combined:=PackedByteArray()
		for piece in pieces: combined.append_array(piece)
		incoming_chunks.erase(seq); snapshot(combined)
	var keys: Array=incoming_chunks.keys(); keys.sort()
	while keys.size()>4: incoming_chunks.erase(keys.pop_front())

func capture_input(event: InputEvent) -> void:
	if not playing: return
	if (event is InputEventJoypadButton and event.pressed and event.button_index==JOY_BUTTON_Y) or (event is InputEventKey and event.pressed and event.physical_keycode==KEY_C):
		game.camera_mode=0 if game.camera_mode==3 else 3; game.set_camera(); get_viewport().set_input_as_handled(); return
	if event.is_action_pressed("start") or (event is InputEventKey and event.pressed and event.physical_keycode==KEY_ESCAPE):
		pause_request(not game.paused); get_viewport().set_input_as_handled(); return
	if game.paused: return
	for button in ["action","alternate","dump"]:
		if event.is_action_pressed(button): send_command(button,true)
		if event.is_action_released(button): send_command(button,false)
	get_viewport().set_input_as_handled()

func axes() -> Dictionary:
	return {"direction":game.stick(),"left":Input.get_action_strength("block_left"),"right":Input.get_action_strength("block_right")}

func send_axes() -> void:
	var value:=axes(); inputs[local_side]=value
	if local_side==1: control_axes.rpc_id(1,value)

@rpc("any_peer","call_remote","unreliable_ordered",2)
func control_axes(value: Dictionary) -> void:
	if authority() and playing and multiplayer.get_remote_sender_id()==guest: accept_axes(1,value)

func accept_axes(side: int,value: Dictionary) -> void:
	var direction=value.get("direction",Vector2.ZERO)
	if not direction is Vector2 or not direction.is_finite(): return
	inputs[side]={"direction":direction.limit_length(),"left":clampf(float(value.get("left",0)),0,1),"right":clampf(float(value.get("right",0)),0,1)}

func send_command(button: String, pressed: bool) -> void:
	sequence+=1
	var value:=axes(); inputs[local_side]=value
	var held:=-1.0
	if not authority():
		var phase: String=game.phase.trim_prefix("CPU_")
		var own: bool=(game.server if phase=="SERVE" else game.possession)==local_side
		var chargeable: bool=own and button in ["action","alternate"] and (phase in ["SERVE","ATTACK"] or (phase=="SET" and game.armed and button=="action"))
		if pressed and chargeable and local_charge_start<0:
			local_charge_start=Time.get_ticks_usec()/1000000.0; local_charge_kind="serve" if phase=="SERVE" else "attack"; local_charge_button=button; local_charge_released=-1
		elif not pressed and button==local_charge_button and local_charge_start>=0:
			if game.use_player_stats and local_charge_kind=="attack":
				sync_local_release()
			held=maxf(0,Time.get_ticks_usec()/1000000.0-local_charge_start)
			if game.use_player_stats and local_charge_kind=="attack" and phase=="SET": held=0
			local_charge_released=held/game.charge_seconds(local_charge_kind)
			local_charge_expiry=Time.get_ticks_usec()/1000000.0+.25; local_charge_start=-1
	if authority(): apply_command(0,sequence,button,pressed,value,held)
	else: control_command.rpc_id(1,sequence,button,pressed,value,held)

func sync_local_release() -> void:
	if game.phase.trim_prefix("CPU_")!="ATTACK" or local_charge_release_seen==game.stats_release_clock: return
	local_charge_release_seen=game.stats_release_clock
	if local_charge_start>=0: local_charge_start=Time.get_ticks_usec()/1000000.0-maxf(0,game.clock_time-game.stats_release_clock)
	else: local_charge_released=0.0

func predicted_charge() -> float:
	if authority() or not playing: return -1
	var phase: String=game.phase.trim_prefix("CPU_")
	var valid: bool=(phase=="SERVE" and game.server==local_side) if local_charge_kind=="serve" else (phase in ["SET","ATTACK"] and game.possession==local_side)
	if not valid:
		local_charge_start=-1; local_charge_released=-1; return -1
	if game.use_player_stats and local_charge_kind=="attack":
		if phase=="SET": return 0.0
		sync_local_release()
	if local_charge_start>=0: return maxf(0,Time.get_ticks_usec()/1000000.0-local_charge_start)/game.charge_seconds(local_charge_kind)
	return local_charge_released if Time.get_ticks_usec()/1000000.0<local_charge_expiry else -1

@rpc("any_peer","call_remote","reliable",0)
func control_command(seq: int, button: String, pressed: bool, value: Dictionary, held: float) -> void:
	if authority() and multiplayer.get_remote_sender_id()==guest: apply_command(1,seq,button,pressed,value,held)

func apply_command(side: int,seq: int,button: String,pressed: bool,value: Dictionary,held: float=-1.0) -> void:
	if game.replay!=null and game.replay.active: return
	if not playing or game.paused or seq<=last_sequence[side] or button not in ["action","alternate","dump"]: return
	last_sequence[side]=seq; accept_axes(side,value)
	game.input_team=side; game.apply_direction(inputs[side].get("direction",Vector2.ZERO),0)
	if not pressed and side==1 and side==(game.server if game.phase=="SERVE" else game.possession) and is_finite(held) and held>=0:
		# The local bar and released power use the same held duration. Network
		# jitter must not turn the guest's visible 100% into an overcharge.
		if game.use_player_stats and game.phase in ["ATTACK","CPU_ATTACK"]: held=minf(held,maxf(0,game.clock_time-game.stats_release_clock))
		if game.charging and game.charge_button==button: game.charge_start=game.clock_time-clampf(held,0,30)
		if game.attack_buffer_start>=0: game.attack_buffer_start=game.clock_time-clampf(held,0,30)
	if pressed: game.press_action(button)
	elif button==game.charge_button or game.attack_buffer_start>=0: game.release_action()
	game.input_team=0

func apply_controls(dt: float) -> void:
	if not authority(): return
	if not test_mode: inputs[0]=axes()
	for side in 2:
		game.input_team=side; game.apply_direction(inputs[side].get("direction",Vector2.ZERO),dt)
	game.input_team=0

func wall_strength(action: String) -> float:
	return float(inputs[game.wall_team()].get("left" if action=="block_left" else "right",0))

func pause_request(value: bool) -> void:
	if not playing: return
	if authority(): game.paused=value
	else: pause_command.rpc_id(1,value)

@rpc("any_peer","call_remote","reliable",0)
func pause_command(value: bool) -> void:
	if authority() and playing and multiplayer.get_remote_sender_id()==guest: game.paused=value

@rpc("authority","call_remote","reliable",0)
func replay_notice(kind: String,token: int,start: float) -> void:
	if playing and local_side==1 and kind in ["serve","attack","monster"]: game.replay.queue(kind,token,start)

func request_replay_skip() -> void:
	if authority():
		game.replay.begin_exit()
		if guest!=0: replay_skip.rpc_id(guest)
	elif playing: replay_skip_request.rpc_id(1)

@rpc("any_peer","call_remote","reliable",0)
func replay_skip_request() -> void:
	if authority() and playing and multiplayer.get_remote_sender_id()==guest and game.replay.active: request_replay_skip()

@rpc("authority","call_remote","reliable",0)
func replay_skip() -> void:
	if playing and local_side==1: game.replay.begin_exit()

@rpc("authority","call_remote","reliable",0)
func replay_finished() -> void:
	if playing and local_side==1: game.replay.finish()
