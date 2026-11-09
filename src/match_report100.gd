extends CanvasLayer
const UI=preload("res://src/career_widgets.gd")
const KEYS=["points","attack_kills","attack_attempts","attack_errors","attacks_blocked","aces","serve_attempts","serve_errors","blocks","block_contacts","receptions","reception_positive","reception_perfect","digs","sets"]
var game
var panel: Control
var history: Array=[]
var baseline: Dictionary={}
var pending: Dictionary={}
var payload: Dictionary={}
var votes: Array=["",""]
var opened:=false
var side:=0
var selected_set:=-1
var details:=false
var status: Label
var nav_wait:=0.0
func _ready():layer=30
func reset():
	history.clear();baseline.clear();pending.clear();payload.clear();votes=["",""];opened=false
	if is_instance_valid(panel):panel.queue_free()
func capture(score: Array):
	if not game.match_management.active:return
	var measured: Dictionary=game.match_management.measured.duplicate(true)
	var delta: Dictionary={}
	for id in measured:
		delta[id]={}
		for key in KEYS:delta[id][key]=maxi(0,int(measured[id].get(key,0))-int(baseline.get(id,{}).get(key,0)))
	history.append({"score":score.duplicate(),"players":delta})
	baseline=measured.duplicate(true)
	var identities: Array=[[],[]]
	var clubs: Array=["",""]
	var db=preload("res://src/league.gd").new()
	for team in 2:
		for p in game.match_management.rosters[team]:identities[team].append({"id":str(p.id),"name":str(p.name),"number":int(p.get("jersey_number",0)),"role":str(p.role)})
		var raw: String=str(identities[team][0].id).get_slice("|",1) if "|" in str(identities[team][0].id) else str(identities[team][0].id)
		for club in db.teams:
			if club.roster.any(func(p):return str(p.id)==raw):clubs[team]=str(club.id);break
	pending={"history":history.duplicate(true),"players":measured,"rosters":identities,"names":game.team_names.duplicate(),"clubs":clubs}
func _process(_dt):
	nav_wait=maxf(0,nav_wait-_dt)
	if pending.is_empty() or opened:return
	if not game.started:return
	if game.replay!=null and game.replay.active:return
	if game.substitution_scene!=null and game.substitution_scene.active:return
	if game.phase!="POINT" or game.phase_time<2.0:return
	pending.final=game.match_finished;pending.sets=game.sets.duplicate()
	if game.network_match():
		if game.online_session.authority():game.online_session.open_report100(pending)
	else:show_report(pending)
	pending={}
func show_report(value: Dictionary):
	payload=value.duplicate(true);opened=true;votes=["",""];selected_set=-1 if payload.final else payload.history.size()-1
	game.paused=true;draw_page()
func rows() -> Dictionary:return payload.players if selected_set<0 else payload.history[selected_set].players
func totals(team: int) -> Dictionary:
	var sum: Dictionary={}
	for key in KEYS:sum[key]=0
	for p in payload.rosters[team]:
		for key in KEYS:sum[key]+=int(rows().get(p.id,{}).get(key,0))
	return sum
func draw_page():
	if is_instance_valid(panel):panel.queue_free()
	panel=Control.new();panel.theme=UI.theme();add_child(panel);panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg:=ColorRect.new();bg.color=Color("071321");panel.add_child(bg);bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var stage:=Control.new();panel.add_child(stage);stage.size=Vector2(1920,1080)
	var fit: float=minf(get_viewport().get_visible_rect().size.x/1920.0,get_viewport().get_visible_rect().size.y/1080.0)
	stage.scale=Vector2.ONE*fit;stage.position=(get_viewport().get_visible_rect().size-stage.size*fit)*.5
	var margin:=MarginContainer.new();stage.add_child(margin);margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left","right","top","bottom"]:margin.add_theme_constant_override("margin_"+edge,28)
	var col:=VBoxContainer.new();col.add_theme_constant_override("separation",12);margin.add_child(col)
	UI.label(col,"MATCH CENTER  /  "+("FINE PARTITA" if payload.final else "FINE SET"),20,UI.GOLD)
	var title:=HBoxContainer.new();title.add_theme_constant_override("separation",24);col.add_child(title)
	for team in 2:
		if team==1:UI.heading(title,"%d  —  %d"%[int(payload.sets[0]),int(payload.sets[1])],38)
		var mark:=TextureRect.new();mark.texture=preload("res://src/league_branding.gd").logo(payload.clubs[team],true);mark.custom_minimum_size=Vector2(58,58);mark.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;mark.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;title.add_child(mark)
		var label=UI.label(title,str(payload.names[team]),23);label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;label.clip_text=true
	var tabs:=HBoxContainer.new();col.add_child(tabs)
	UI.button(tabs,"PARTITA",func():selected_set=-1;draw_page(),"total")
	for index in payload.history.size():
		var n: int=index;var score: Array=payload.history[index].score
		UI.button(tabs,"SET %d  ·  %d–%d"%[index+1,int(score[0]),int(score[1])],func():selected_set=n;draw_page(),"set"+str(index))
	var body:=HBoxContainer.new();body.size_flags_vertical=Control.SIZE_EXPAND_FILL;body.add_theme_constant_override("separation",20);col.add_child(body)
	var comparisons=UI.card(body,500);comparisons.get_parent().size_flags_horizontal=Control.SIZE_FILL;UI.heading(comparisons,"IL CONFRONTO",25)
	var a: Dictionary=totals(0);var b: Dictionary=totals(1)
	for entry in [["attack_kills","ATTACCHI VINCENTI"],["aces","ACE"],["blocks","MURI PUNTO"],["block_contacts","TOCCHI A MURO"],["digs","DIFESE"],["serve_errors","ERRORI IN BATTUTA"],["attack_errors","ERRORI IN ATTACCO"]]:
		var line:=HBoxContainer.new();comparisons.add_child(line);UI.label(line,str(a[entry[0]]),22,UI.GOLD);var text=UI.label(line,entry[1],13);text.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;text.size_flags_horizontal=Control.SIZE_EXPAND_FILL;UI.label(line,str(b[entry[0]]),22,UI.GOLD)
		var bar:=ProgressBar.new();bar.max_value=maxi(1,int(a[entry[0]])+int(b[entry[0]]));bar.value=a[entry[0]];bar.show_percentage=false;bar.custom_minimum_size.y=5;comparisons.add_child(bar)
	var players=UI.card(body);players.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var team_tabs:=HBoxContainer.new();players.add_child(team_tabs)
	for team in 2:
		var t: int=team;UI.button(team_tabs,str(payload.names[team]),func():side=t;draw_page(),"team"+str(team))
	UI.button(team_tabs,"DETTAGLIO" if not details else "SINTESI",func():details=not details;draw_page(),"details")
	var scroll:=ScrollContainer.new();scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;players.add_child(scroll)
	var table:=VBoxContainer.new();table.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(table)
	var headers:=HBoxContainer.new();table.add_child(headers)
	var head=UI.label(headers,"GIOCATORE",13,UI.MUTED);head.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	for caption in (["BAT","ERR B","TOC","RIC","ERR A","SUB M","POS","PRF"] if details else ["PT","ATT","ACE","MUR","RIC+","RIC#","DIF","ALZ"]):
		var cell=UI.label(headers,caption,16,UI.MUTED);cell.custom_minimum_size.x=56;cell.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	head.tooltip_text="Attacchi vincenti/totali · Ricezioni positive e perfette in percentuale · Difese · Alzate"
	for p in payload.rosters[side]:
		var values: Dictionary=rows().get(p.id,{})
		var count: int=int(values.get("receptions",0));var positive: String="—" if count==0 else "%d%%"%roundi(float(values.get("reception_positive",0))*100/count);var perfect: String="—" if count==0 else "%d%%"%roundi(float(values.get("reception_perfect",0))*100/count)
		var line:=HBoxContainer.new();table.add_child(line)
		var who:=Button.new();who.text="%d · %s"%[p.number,p.name];who.tooltip_text=p.name;who.alignment=HORIZONTAL_ALIGNMENT_LEFT;who.size_flags_horizontal=Control.SIZE_EXPAND_FILL;who.clip_text=true;who.custom_minimum_size.y=38;who.add_theme_font_size_override("font_size",19);line.add_child(who);who.focus_entered.connect(func():scroll.ensure_control_visible(who))
		var numbers: Array=[str(values.get("points",0)),"%d/%d"%[values.get("attack_kills",0),values.get("attack_attempts",0)],str(values.get("aces",0)),str(values.get("blocks",0)),positive,perfect,str(values.get("digs",0)),str(values.get("sets",0))]
		if details:numbers=[str(values.get("serve_attempts",0)),str(values.get("serve_errors",0)),str(values.get("block_contacts",0)),str(count),str(values.get("attack_errors",0)),str(values.get("attacks_blocked",0)),str(values.get("reception_positive",0)),str(values.get("reception_perfect",0))]
		for text in numbers:
			var cell:=Label.new();cell.text=text;cell.custom_minimum_size.x=56;cell.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;cell.add_theme_font_size_override("font_size",16);line.add_child(cell)
	status=UI.label(col,"",16,UI.GOLD);update_votes(votes)
	var actions:=HBoxContainer.new();actions.add_theme_constant_override("separation",16);col.add_child(actions)
	var first: Button
	if not payload.final:first=UI.button(actions,"CONTINUA",func():choose("continue"),"continue")
	else:
		first=UI.button(actions,"RIVINCITA",func():choose("rematch"),"rematch")
		if game.network_match():UI.button(actions,"SELEZIONA SQUADRA / LOBBY",func():choose("lobby"),"lobby")
		else:UI.button(actions,"TORNA AL MENU",func():choose("menu"),"menu")
	if not game.network_match() and payload.final and career_match():first.disabled=true;first=actions.get_child(actions.get_child_count()-1)
	UI.label(col,"A / Croce: conferma · stick sinistro / D-pad: naviga · L1/R1: squadra",14,UI.MUTED)
	first.grab_focus()
func career_match() -> bool:
	if game.legend_match!=null and game.legend_match.active:return true
	for node in game.get_children():
		if node.get_script()==preload("res://src/start_menu.gd") and not node.career_menu.active_fixture.is_empty():return true
	return false
func update_votes(value: Array):
	votes=value.duplicate()
	var captions: Dictionary={"":"IN ATTESA","continue":"CONTINUA","rematch":"RIVINCITA","lobby":"SELEZIONA SQUADRA"}
	if is_instance_valid(status):status.text="Confermate entrambi la stessa scelta.  Casa: %s  ·  Ospite: %s"%[captions.get(votes[0],"IN ATTESA"),captions.get(votes[1],"IN ATTESA")] if game.network_match() else "STATISTICHE RILEVATE DURANTE LA PARTITA"
func choose(action: String):
	if game.network_match():game.online_session.vote_report100(action)
	else:resolve(action)
func resolve(action: String):
	opened=false;pending={};game.paused=false
	if is_instance_valid(panel):panel.queue_free()
	if action=="continue":
		game.phase_time=0
		if not game.network_match() or game.online_session.authority():game.reset_rally()
	elif action=="menu":game.return_to_main_menu()
	elif action=="rematch":
		var m=game.match_management;var teams: Array=[{"roster":m.rosters[0]},{"roster":m.rosters[1]}];var squads: Array=[]
		for team in 2:
			var squad: Array=[]
			for id in m.current[team]:squad.append(m.identity(id))
			squad.append(m.identity(m.libero_ids[team]));squads.append(squad)
		var C=preload("res://src/condition99.gd");var ledger: Dictionary=C.fresh();C.ensure(ledger,m.rosters[0]+m.rosters[1])
		m.configure_rosters(teams,squads,{}, {"condition99":ledger,"fatigue":m.fatigue_enabled,"injuries":m.injuries_enabled})
		game.scores=[0,0];game.sets=[0,0];game.match_finished=false;game.server=0;game.reset_rally()
func _input(event):
	if not opened:return
	if event is InputEventJoypadMotion and event.axis in [JOY_AXIS_LEFT_X,JOY_AXIS_LEFT_Y] and absf(event.axis_value)>.55 and nav_wait<=0:
		UI.navigate(panel,Vector2(signf(event.axis_value),0) if event.axis==JOY_AXIS_LEFT_X else Vector2(0,signf(event.axis_value)));nav_wait=.18;get_viewport().set_input_as_handled()
	if event is InputEventJoypadButton and event.pressed:
		if event.button_index in [JOY_BUTTON_LEFT_SHOULDER,JOY_BUTTON_RIGHT_SHOULDER]:side=1-side;draw_page()
		elif event.button_index==JOY_BUTTON_A:
			var owner=get_viewport().gui_get_focus_owner()
			if owner is Button and not owner.disabled:owner.pressed.emit()
		elif event.button_index in [JOY_BUTTON_DPAD_DOWN,JOY_BUTTON_DPAD_UP,JOY_BUTTON_DPAD_LEFT,JOY_BUTTON_DPAD_RIGHT]:
			UI.navigate(panel,{JOY_BUTTON_DPAD_DOWN:Vector2.DOWN,JOY_BUTTON_DPAD_UP:Vector2.UP,JOY_BUTTON_DPAD_LEFT:Vector2.LEFT,JOY_BUTTON_DPAD_RIGHT:Vector2.RIGHT}[event.button_index])
		get_viewport().set_input_as_handled()
