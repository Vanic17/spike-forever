extends Control
const UI=preload("res://src/career_widgets.gd")
const League=preload("res://src/league.gd")
const Kits=preload("res://src/club_kits.gd")
const TABS=["HOME","CALENDARIO","CLASSIFICA","COMPETIZIONI","ROSA","STATISTICHE","NOTIZIE","ARCHIVIO","IMPOSTAZIONI"]
const COMPS={"regular":"SuperLega","playoff":"Playoff Scudetto","cup":"Coppa Italia","supercup":"Supercoppa","fifth":"Playoff 5° posto","playout":"Play Out"}
var host
var game
var manager
var frame: Control
var page: VBoxContainer
var header: HBoxContainer
var nav: HBoxContainer
var hint: Label
var notice: Label
var view:="entry"
var argument=""
var tab_index:=0
var stack: Array=[]
var round_index:=0
var calendar_mode:=0
var filter_team:=""
var filter_comp:=""
var calendar_month:=10
var sort_stat:="points"
var selected_stats_comp:=""
var selected_stats_role:=""
var selected_stats_season:=""
var selected_stats_match:=""
var news_query:=""
var news_page:=0
var archive_index:=-1
var selected_comp:="regular"
var dirty_options:=false
var modal_dirty:=false
var modal: AcceptDialog
var modal_previous_key:=""
var axis_wait:=0.0
var held_direction:=Vector2.ZERO
var active_fixture: Dictionary={}
var pending_post: Dictionary={}
var chosen_kits: Array=["home","away"]
var editing_options: Dictionary={}
var saved_focus:=""

func _ready():
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); theme=UI.theme()
	var bg=ColorRect.new(); bg.color=Color("091422"); bg.mouse_filter=Control.MOUSE_FILTER_IGNORE; add_child(bg); bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame=Control.new(); frame.size=Vector2(1920,1080); add_child(frame)
	header=HBoxContainer.new(); frame.add_child(header); header.position=Vector2(48,26); header.size=Vector2(1824,100)
	nav=HBoxContainer.new(); frame.add_child(nav); nav.position=Vector2(48,143); nav.size=Vector2(1824,58); nav.add_theme_constant_override("separation",8)
	page=VBoxContainer.new(); frame.add_child(page); page.position=Vector2(48,225); page.size=Vector2(1824,780)
	hint=UI.label(frame,"",21,UI.MUTED); hint.position=Vector2(48,1027); hint.size=Vector2(1824,34)
	resized.connect(layout); layout(); hide()
func layout():
	if frame==null: return
	var factor=minf(size.x/1920.0,size.y/1080.0); frame.scale=Vector2.ONE*factor; frame.position=(size-Vector2(1920,1080)*factor)*.5
func ensure_manager():
	if manager==null: manager=load("res://src/career_manager.gd").new()
func open():
	ensure_manager(); host.play_hub.hide(); host.clubs.hide(); host.online_menu.hide(); host.overlay.hide(); stack.clear(); show_page("entry")
func clear(node: Node):
	for child in node.get_children(): node.remove_child(child); child.queue_free()
func name_of(id: String) -> String:
	var t=manager.team(id) if not manager.state.is_empty() else {}
	if t.is_empty():
		for candidate in host.clubs.db.teams:
			if candidate.id==id: return candidate.name
	return t.get("name",id)
func short(id: String) -> String: return UI.Brand.data().clubs.get(id,{}).get("abbreviation",id.left(3).to_upper())
func season() -> String: return manager.state.get("season_label","2026/27")
func club() -> String: return manager.state.get("club_id","")
func state_fixtures() -> Array: return manager.state.get("fixtures",[])
func focus_key() -> String:
	var owner=get_viewport().gui_get_focus_owner(); return str(owner.get_meta("focus_key","")) if owner!=null else ""
func focus_restore(key: String=""):
	var list=UI.controls(page)
	for control in list:
		if control.get_meta("focus_key","")==key: control.grab_focus(); return
	if not list.is_empty(): list[0].grab_focus()
func push(next: String,arg=""):
	stack.append({"view":view,"arg":argument,"focus":focus_key()}); show_page(next,arg)
func back():
	if view=="impostazioni" and dirty_options:
		confirm("Ci sono modifiche non salvate. Vuoi uscire senza applicarle?",func(): dirty_options=false; back()); return
	if not stack.is_empty():
		var previous=stack.pop_back(); show_page(previous.view,previous.arg); call_deferred("focus_restore",previous.focus)
	elif view!="entry": show_page("entry")
	else: hide(); host.play_hub.open()
func show_tab(index: int):
	if view=="impostazioni" and dirty_options:
		confirm("Ci sono modifiche non salvate. Vuoi uscire senza applicarle?",func(): dirty_options=false; show_tab(index)); return
	stack.clear(); tab_index=posmod(index,TABS.size()); show_page(TABS[tab_index].to_lower())
func show_page(next: String,arg=""):
	view=next; argument=arg; clear(header); clear(nav); clear(page); show()
	header.alignment=BoxContainer.ALIGNMENT_BEGIN
	var id=club(); if not id.is_empty(): UI.badge(header,id,80)
	var title_box=VBoxContainer.new(); title_box.size_flags_horizontal=Control.SIZE_EXPAND_FILL; header.add_child(title_box)
	title_box.add_theme_constant_override("separation",3)
	var title=UI.heading(title_box,"CAMPIONATO / SUPERLEGA" if id.is_empty() else name_of(id),35); title.autowrap_mode=TextServer.AUTOWRAP_OFF; title.clip_text=true
	UI.label(title_box,"MASTER LEAGUE  ·  "+season()+"  ·  "+manager.state.get("date","Nuova carriera"),19,UI.MUTED)
	if not manager.state.is_empty(): UI.label(title_box,"%d incontri disputati   ·   Salvataggio locale / Slot %d"%[manager.state.get("results",{}).size(),int(manager.state.get("slot",1))],16,UI.GOLD)
	if not manager.state.is_empty():
		var save=UI.button(header,"SALVA",func(): toast("Carriera salvata" if manager.save() else manager.error),"save"); save.size_flags_horizontal=Control.SIZE_SHRINK_END; save.size_flags_vertical=Control.SIZE_SHRINK_CENTER; save.custom_minimum_size=Vector2(128,54)
	var back_button=UI.button(header,"INDIETRO",back,"back"); back_button.size_flags_horizontal=Control.SIZE_SHRINK_END; back_button.size_flags_vertical=Control.SIZE_SHRINK_CENTER; back_button.custom_minimum_size=Vector2(148,54)
	if not manager.state.is_empty() and next not in ["entry","new","saves"]:
		for i in TABS.size():
			var index=i; var b=UI.button(nav,TABS[i],func(): show_tab(index),"tab-"+str(i)); b.add_theme_font_size_override("font_size",20)
			if TABS[i].to_lower()==next: b.add_theme_stylebox_override("normal",UI.surface(Color("415377"),12,14))
	match next:
		"entry": entry()
		"new": new_career_screen()
		"saves": saves_screen()
		"home": home_screen()
		"calendario": calendar_screen()
		"classifica": standings_screen()
		"competizioni": competitions_screen()
		"rosa": squad_screen(club())
		"team": team_screen(str(arg))
		"roster-team": squad_screen(str(arg))
		"player": player_screen(str(arg))
		"statistiche": stats_screen()
		"notizie": news_screen()
		"article": article_screen(str(arg))
		"archivio": archive_screen()
		"impostazioni": options_screen()
		"prematch": prematch_screen()
		"result": result_screen(str(arg))
	update_hints(); call_deferred("focus_restore")
func update_hints():
	var device=game.pad(); var ps=false
	if device>=0:
		var n=Input.get_joy_name(device).to_lower(); ps="sony" in n or "dual" in n or "playstation" in n or ("wireless controller" in n and not "xbox" in n)
	hint.text=("X: scegli   ○: indietro   L1/R1: schede   L2/R2: giornate   □: simula   OPTIONS: salva" if ps else "A: scegli   B: indietro   LB/RB: schede   LT/RT: giornate   X: simula   MENU: salva") if device>=0 else "Frecce: naviga   Invio: scegli   Esc: indietro   Pag↑/Pag↓: schede   Q: simula   F5: salva"
func toast(text: String):
	var previous=focus_key()
	var dialog=AcceptDialog.new(); dialog.title="CAMPIONATO"; dialog.dialog_text=text; add_child(dialog); dialog.popup_centered(Vector2i(680,210)); dialog.get_ok_button().grab_focus(); dialog.confirmed.connect(func(): dialog.queue_free(); focus_restore(previous))
	dialog.canceled.connect(func(): dialog.queue_free(); focus_restore(previous))
func confirm(text: String,action: Callable):
	var previous=focus_key()
	var dialog=ConfirmationDialog.new(); dialog.title="CONFERMA"; dialog.dialog_text=text; dialog.ok_button_text="CONFERMA"; dialog.cancel_button_text="ANNULLA"; dialog.exclusive=true; add_child(dialog)
	dialog.confirmed.connect(func(): dialog.queue_free(); action.call()); dialog.canceled.connect(func(): dialog.queue_free(); focus_restore(previous))
	dialog.popup_centered(Vector2i(720,260)); dialog.get_cancel_button().grab_focus()
func image(parent: Node,id: String,height: float=220) -> TextureRect:
	var tex=TextureRect.new(); tex.texture=UI.Brand.texture("assets/ui/career66/"+id+".png"); tex.custom_minimum_size.y=height; tex.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; tex.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED; tex.size_flags_horizontal=Control.SIZE_EXPAND_FILL; parent.add_child(tex); return tex
func entry():
	var row=HBoxContainer.new(); row.size_flags_vertical=Control.SIZE_EXPAND_FILL; page.add_child(row)
	var hero=UI.card(row,1100); image(hero,"arena",420); UI.label(hero,"LA TUA SQUADRA. LA TUA STORIA.",24,UI.GOLD); UI.heading(hero,"UNA STAGIONE DA VIVERE",57)
	UI.wrap(hero,"Dodici club, un calendario autentico, sei fondamentali. Gestisci la rosa, preparati alle coppe e porta la tua squadra fino all'ultimo pallone.",25,UI.MUTED)
	var choices=UI.card(row,650); UI.heading(choices,"MASTER LEAGUE",42); UI.wrap(choices,"Il campionato parte senza risultati preassegnati. I tuoi progressi restano salvati su questo PC.",25,UI.MUTED)
	UI.button(choices,"NUOVA CARRIERA  →",func(): push("new"),"new")
	var all=manager.list_saves(); var continue_button=UI.button(choices,"CONTINUA  →",func():
		if not manager.state.is_empty(): show_tab(0)
		elif not all.is_empty() and manager.load_career(int(all[0].slot)): show_tab(0)
		else: toast(manager.error),"continue")
	continue_button.disabled=all.is_empty() and manager.state.is_empty()
	UI.button(choices,"CARICA SALVATAGGIO",func(): push("saves"),"load")
	UI.wrap(choices,"SUPERLEGA 2026/27\n132 incontri ufficiali · Coppa Italia · Supercoppa · Playoff · Play Out\n\nNessuna retrocessione: tutti i dodici club partecipano anche alla stagione seguente.",23,UI.MUTED)
func new_career_screen():
	var row=HBoxContainer.new(); row.size_flags_vertical=Control.SIZE_EXPAND_FILL; page.add_child(row)
	var preview=UI.card(row,790); var badge=UI.badge(preview,host.clubs.db.teams[0].id,110); var name=UI.heading(preview,"",42)
	var kit=load("res://src/kit_preview.gd").new(); kit.custom_minimum_size.y=290; preview.add_child(kit)
	var summary=UI.wrap(preview,"",23,UI.MUTED)
	var right=UI.card(row,990); var form=UI.scroll(right)
	UI.heading(form,"COSTRUISCI LA TUA STAGIONE",38); UI.label(form,"SQUADRA",20,UI.GOLD)
	var teams=host.clubs.db.teams; var team_pick=UI.picker(form,teams.map(func(t): return t.name))
	var refresh=func(_index):
		var t=teams[team_pick.selected]; badge.texture=UI.Brand.logo(t.id,true); name.text=t.name; kit.show_kit(t.id,"home")
		var rating=0.0
		for p in t.roster: rating+=float(p.ratings.get("generale",0))
		summary.text="%d giocatori · valore medio %.0f\nPalazzetto: arena virtuale Spike Forever\nObiettivo: migliorare il piazzamento e conquistare i playoff."%[t.roster.size(),rating/maxi(1,t.roster.size())]
	team_pick.item_selected.connect(refresh); refresh.call(0)
	UI.label(form,"SLOT DI SALVATAGGIO"); var slot=UI.picker(form,["Slot 1","Slot 2","Slot 3","Slot 4","Slot 5","Slot 6"])
	UI.label(form,"DIFFICOLTÀ"); var difficulty=UI.picker(form,["Accessibile","Normale","Impegnativa"],1)
	var controls=options_controls(form,{"stats":true,"fatigue":true,"injuries":true,"autosave":true})
	UI.wrap(form,"Partite al meglio dei 5: set a 25, set decisivo a 15, sempre con due punti di vantaggio.",21,UI.MUTED)
	var coach_text=LineEdit.new(); form.add_child(coach_text); coach_text.hide()
	var coach_button=UI.button(form,"ALLENATORE · facoltativo",func():
		edit_text(coach_text.text,func(value):
			coach_text.text=value
			for b in UI.controls(page):
				if b.get_meta("focus_key","")=="coach": b.text=str(TranslationServer.translate("ALLENATORE · "))+value; b.grab_focus()),"coach")
	UI.button(form,"INIZIA LA CARRIERA",func():
		var opts=read_options(controls); opts.difficulty=difficulty.selected; opts.coach_name=coach_text.text
		var create=func():
			if manager.new_career(teams[team_pick.selected].id,opts,slot.selected+1): stack.clear(); show_tab(0)
			else: toast(manager.error)
		var exists=manager.list_saves().any(func(s): return int(s.slot)==slot.selected+1)
		if exists: confirm("Questo slot contiene già una carriera. Vuoi sostituirla?",create)
		else: create.call(),"create")
func options_controls(parent: Node,options: Dictionary) -> Dictionary:
	var fields={}
	for entry in [["stats","VALORI GIOCATORI",["Disattivati · originale","Attivi · database"]],["fatigue","AFFATICAMENTO",["OFF","ON"]],["injuries","INFORTUNI SIMULATI",["OFF","ON"]],["autosave","SALVATAGGIO AUTOMATICO",["OFF","ON"]],["auto_subs","SOSTITUZIONI AUTOMATICHE",["OFF","ON"]]]:
		UI.label(parent,entry[1],20,UI.MUTED); fields[entry[0]]=UI.picker(parent,entry[2],1 if options.get(entry[0],options.get("use_player_stats",false) if entry[0]=="stats" else entry[0] in ["fatigue","autosave"]) else 0)
	UI.label(parent,"NOTIZIE",20,UI.MUTED); fields.news_frequency=UI.picker(parent,["Essenziali","Normali","Tutte"],int(options.get("news_frequency",1)))
	UI.label(parent,"INFORTUNI · INTENSITÀ",20,UI.MUTED); fields.injury_intensity=UI.picker(parent,["Bassa","Normale"],int(options.get("injury_intensity",0)))
	UI.label(parent,"SIMULAZIONE",20,UI.MUTED); fields.simulation_detail=UI.picker(parent,["Rapida","Dettagliata"],1 if str(options.get("simulation_detail",0)) in ["1","detailed"] else 0)
	for key in fields: fields[key].item_selected.connect(func(_index): if view=="impostazioni": dirty_options=true)
	return fields
func read_options(controls: Dictionary) -> Dictionary:
	var result={}
	for key in controls: result[key]=controls[key].selected==1 if key in ["stats","fatigue","injuries","autosave","auto_subs"] else controls[key].selected
	result.injury_intensity=.65 if controls.injury_intensity.selected==0 else 1.0
	return result
func saves_screen():
	UI.heading(page,"LE TUE CARRIERE",42); var list=UI.scroll(page); var saves=manager.list_saves()
	if saves.is_empty(): UI.wrap(list,"Nessuna carriera salvata. Crea una nuova stagione per iniziare.",26,UI.MUTED)
	for save in saves:
		var record=save
		UI.button(list,"SLOT %d   %s   /   %s   /   %s"%[int(save.slot),name_of(save.get("club_id","")),save.get("season_label",str(save.get("season",2026))),save.get("date","")],func():
			if manager.load_career(int(record.slot)): stack.clear(); show_tab(0)
			else: toast(manager.error),"save-"+str(save.slot))
func home_screen():
	var row=HBoxContainer.new(); page.add_child(row)
	var hero=UI.card(row,1065,420); image(hero,"arena",218)
	var news=manager.state.get("news",[]); UI.label(hero,"DENTRO LA TUA STAGIONE",20,UI.GOLD)
	UI.heading(hero,str(news[0].get("title","LA STAGIONE È NELLE TUE MANI")) if not news.is_empty() else "LA STAGIONE È NELLE TUE MANI",37)
	UI.wrap(hero,str(news[0].get("subtitle",news[0].get("summary","Preparazione, scelte, risultati. Ogni giornata conta."))) if not news.is_empty() else "Prepara la formazione e comincia la tua storia in SuperLega.",22,UI.MUTED)
	var match_card=UI.card(row,720,420); UI.label(match_card,"MATCH CENTER",22,UI.GOLD)
	var fixture=manager.next_fixture()
	if fixture.is_empty():
		if not manager.state.get("complete",false):
			UI.heading(match_card,"IL CAMPIONATO CONTINUA",40); UI.wrap(match_card,"La tua squadra ha concluso gli incontri previsti. Avanza per seguire le altre competizioni fino all'assegnazione dei titoli.",24,UI.MUTED)
			UI.button(match_card,"AVANZA LE COMPETIZIONI",simulate_match,"advance-competitions")
		else:
			UI.heading(match_card,"STAGIONE COMPLETATA",40); UI.wrap(match_card,"I risultati e i premi sono conservati nell'archivio. I dodici club sono pronti per una nuova stagione.",24,UI.MUTED)
			UI.button(match_card,"INIZIA LA STAGIONE SUCCESSIVA",func():
				if manager.next_season(): show_tab(0)
				else: toast(manager.error),"next-season")
	else:
		UI.label(match_card,fixture.get("scheduled_date","")+" · "+COMPS.get(fixture.get("competition","regular"),fixture.get("competition","")),22,UI.MUTED)
		var versus=HBoxContainer.new(); match_card.add_child(versus); UI.badge(versus,fixture.home,87); UI.heading(versus,short(fixture.home)+"  —  "+short(fixture.away),51); UI.badge(versus,fixture.away,87)
		UI.wrap(match_card,name_of(fixture.home)+"\n"+name_of(fixture.away),24)
		var actions=HBoxContainer.new(); match_card.add_child(actions)
		UI.button(actions,"GIOCA  →",func(): push("prematch"),"play-match"); UI.button(actions,"SIMULA",simulate_match,"simulate")
		UI.button(match_card,"FORMAZIONE / GESTISCI SQUADRA",func(): show_tab(4),"manage")
	var bottom=HBoxContainer.new(); bottom.size_flags_vertical=Control.SIZE_EXPAND_FILL; page.add_child(bottom)
	var feed=UI.card(bottom,590); UI.heading(feed,"ULTIME NOTIZIE",30)
	for i in mini(3,news.size()):
		var article=news[i]; UI.button(feed,str(article.get("title","Notizia")),func(): push("article",str(article.get("id",""))),"news-"+str(article.get("id",i)))
	var table=UI.card(bottom,590); UI.heading(table,"LA CORSA IN CLASSIFICA",30)
	for line in manager.standings().slice(0,5):
		var id=str(line.get("team_id",line.get("id",line.get("club_id","")))); var b=UI.button(table,"%s   %s   %s PT"%[str(line.get("position","")),short(id),str(line.get("points",0))],func(): push("team",id),"club-"+id); UI.compact(b)
	var schedule=UI.card(bottom,590); UI.heading(schedule,"IL TUO CAMMINO",30)
	var next=manager.pending_fixtures(club())
	for f in next.slice(0,3): fixture_button(schedule,f)
	if next.is_empty():
		var previous=state_fixtures().filter(func(f): return (f.home==club() or f.away==club()) and not f.result.is_empty())
		previous.reverse()
		for f in previous.slice(0,3): fixture_button(schedule,f)
func simulate_match():
	saved_focus=focus_key(); var result=manager.simulate_next()
	if result.is_empty(): toast(manager.error if not manager.error.is_empty() else "Nessun incontro da simulare.")
	else: push("result",str(result.get("fixture_id",result.get("id",""))))
func fixture_button(parent: Node,fixture: Dictionary):
	var f=fixture; var result=f.get("result",{}); var score=" — "
	if not result.is_empty(): score=" %d–%d "%[int(result.sets[0]),int(result.sets[1])]
	UI.button(parent,f.get("scheduled_date","")+"   "+short(f.home)+score+short(f.away),func(): push("result",str(f.id)),"fixture-"+str(f.id))
func calendar_screen():
	UI.heading(page,"OGNI GIORNATA, OGNI PALLONE",40)
	var toolbar=HBoxContainer.new(); page.add_child(toolbar)
	var mode=UI.picker(toolbar,["Giornata","Mese"],calendar_mode); mode.item_selected.connect(func(i): calendar_mode=i; show_page(view))
	var comps=[""]+COMPS.keys(); var comp=UI.picker(toolbar,["Tutte le competizioni"]+COMPS.values(),maxi(0,comps.find(filter_comp)))
	comp.item_selected.connect(func(i): filter_comp=comps[i]; show_page(view))
	var teams=[""]+manager.state.teams.map(func(t): return t.id)
	var team=UI.picker(toolbar,["Tutte le squadre"]+manager.state.teams.map(func(t): return t.name),maxi(0,teams.find(filter_team)))
	team.item_selected.connect(func(i): filter_team=teams[i]; show_page(view))
	var filtered=state_fixtures().filter(func(f): return (filter_comp.is_empty() or f.competition==filter_comp) and (filter_team.is_empty() or f.home==filter_team or f.away==filter_team))
	if calendar_mode==0:
		var round_pick=UI.picker(toolbar,Array(range(1,23)).map(func(i): return "Giornata "+str(i)),round_index)
		round_pick.item_selected.connect(func(i): round_index=i; show_page(view))
		var list=UI.scroll(page)
		for fixture in filtered:
			if int(fixture.get("round",1))==round_index+1: fixture_button(list,fixture)
		UI.button(page,"RISOLVI LA PROSSIMA GIORNATA",func(): confirm("Simulare tutti gli incontri necessari fino alla prossima partita della tua squadra?",func(): manager.simulate_day(); show_page(view)),"simulate-day")
	else:
		var months=["Ottobre","Novembre","Dicembre","Gennaio","Febbraio","Marzo","Aprile","Maggio","Giugno"]
		var month_index=posmod(calendar_month-10,12); var pick=UI.picker(toolbar,months,clampi(month_index,0,8))
		pick.item_selected.connect(func(i): calendar_month=posmod(i+9,12)+1; show_page(view))
		var row=HBoxContainer.new(); row.size_flags_vertical=Control.SIZE_EXPAND_FILL; page.add_child(row)
		var month=UI.card(row,850); var grid=GridContainer.new(); grid.columns=7; grid.add_theme_constant_override("h_separation",8); grid.add_theme_constant_override("v_separation",8); month.add_child(grid)
		var year=int(manager.state.season)+(1 if calendar_month<8 else 0)
		var month_prefix="%04d-%02d-"%[year,calendar_month]
		for day in 31:
			var date=month_prefix+"%02d"%(day+1)
			if not valid_date(date): continue
			var count=filtered.filter(func(f): return f.scheduled_date==date).size()
			var b=UI.button(grid,"%02d\n%s"%[day+1,str(count)+" gare" if count else "—"],func(): day_dialog(date,filtered),"day-"+date); b.custom_minimum_size=Vector2(102,80)
		var list=UI.card(row,900); UI.heading(list,months[pick.selected]+" / "+str(year),32); var scroll=UI.scroll(list)
		for fixture in filtered:
			if str(fixture.scheduled_date).begins_with(month_prefix): fixture_button(scroll,fixture)
func valid_date(date: String) -> bool:
	var stamp=Time.get_unix_time_from_datetime_string(date+"T12:00:00")
	return Time.get_datetime_string_from_unix_time(int(stamp)).left(10)==date
func day_dialog(date: String,fixtures: Array):
	var chosen=fixtures.filter(func(f): return f.scheduled_date==date)
	var body="\n".join(chosen.map(func(f): return name_of(f.home)+" — "+name_of(f.away)))
	confirm(date+"\n"+(body if not body.is_empty() else "Giornata senza partite")+"\n\nVuoi simulare e avanzare fino a questa data?",func(): manager.advance_to(date); show_page("calendario"))
func standings_screen():
	UI.heading(page,"LA CLASSIFICA",42)
	var widths=[54,475,70,55,55,55,112,100,100,185]
	var list=UI.scroll(page)
	UI.table_header(list,["POS","SQUADRA","PT","G","V","P","SET +/−","QS","QP","FORMA"],widths)
	var index=0
	for line in manager.standings():
		index+=1; var id=str(line.get("team_id",line.get("id",line.get("club_id",""))))
		var played=int(line.get("played",line.get("matches",0))); var wins=int(line.get("wins",0)); var sf=int(line.get("sets_for",line.get("sets_won",0))); var sa=int(line.get("sets_against",line.get("sets_lost",0)))
		var form=line.get("form",line.get("recent",[])); var form_text=" ".join(form) if form is Array else str(form)
		UI.table_row(list,["%02d"%index,name_of(id),line.get("points",0),played,wins,played-wins,"%d/%d"%[sf,sa],quotient(sf,sa),quotient(int(line.get("points_for",0)),int(line.get("points_against",0))),form_text],widths,func(): push("team",id),"club-"+id)
func quotient(numerator: int,denominator: int) -> String:
	return "—" if numerator==0 and denominator==0 else "∞" if denominator==0 else "%.2f"%(float(numerator)/denominator)
func competitions_screen():
	UI.heading(page,"LE COMPETIZIONI",42)
	var picker=UI.picker(page,COMPS.values(),maxi(0,COMPS.keys().find(selected_comp)))
	picker.item_selected.connect(func(i): selected_comp=COMPS.keys()[i]; show_page(view))
	var info=manager.state.get("competitions",{}).get(selected_comp,{})
	var champion=str(info.get("champion",""))
	UI.label(page,"Campione: "+name_of(champion) if not champion.is_empty() else "Competizione in corso" if info.get("status","waiting")!="waiting" else "Qualificazioni in attesa dei risultati previsti",24,UI.GOLD)
	var rules_text={"regular":"22 giornate · 3/2/1 punti secondo il risultato","playoff":"Prime otto · quarti, semifinali e finale al meglio delle cinque","cup":"Prime otto al termine dell'andata · quarti e Final Four · sede 2027 non ancora ufficializzata","supercup":"Supercoppa 2026: semifinali e finale a Parma, 14–15 novembre. Dalle stagioni seguenti qualificazioni dai risultati del salvataggio.","fifth":"Percorso condizionato dai playoff: quattro eliminate ai quarti, oppure girone a tre e finale con una semifinalista Scudetto.","playout":"Tre o quattro squadre secondo il distacco 9ª–12ª. Bonus regolamentari. Nessuna retrocessione in Spike Forever."}
	UI.wrap(page,rules_text.get(selected_comp,""),22,UI.MUTED)
	var list=UI.scroll(page)
	var matches=state_fixtures().filter(func(f): return f.competition==selected_comp)
	var series=info.get("series",[])
	if not series.is_empty():
		var bracket=HBoxContainer.new(); bracket.add_theme_constant_override("separation",18); list.add_child(bracket)
		var stages=[]
		for entry in series:
			if not entry.stage in stages: stages.append(entry.stage)
		stages.sort()
		for stage in stages:
			var column=VBoxContainer.new(); column.size_flags_horizontal=Control.SIZE_EXPAND_FILL; bracket.add_child(column)
			UI.heading(column,{1:"QUARTI",2:"SEMIFINALI",3:"FINALE"}.get(int(stage),"FASE "+str(stage)) if selected_comp=="playoff" else ("SEMIFINALI" if int(stage)==1 else "FINALE"),28)
			for entry in series.filter(func(item): return item.stage==stage):
				var card=UI.card(column); UI.label(card,"AL MEGLIO DELLE "+str(entry.best_of),18,UI.GOLD)
				for side in 2:
					var id=str(entry.team_a if side==0 else entry.team_b)
					var b=UI.button(card,short(id)+"   "+name_of(id)+"   ·   "+str(entry.wins[side]),func(): push("team",id),"bracket-"+str(entry.id)+id); UI.compact(b)
				if not str(entry.winner).is_empty(): UI.label(card,"Vincente: "+short(entry.winner),21,UI.GOLD)
				for match_id in entry.games:
					var f=manager.fixture(str(match_id)); fixture_button(card,f)
	if selected_comp in ["cup","supercup"]:
		var bracket=HBoxContainer.new(); list.add_child(bracket)
		for stage in ["quarter","semi","final"]:
			var games=matches.filter(func(f): return f.get("stage","")==stage)
			if games.is_empty(): continue
			var column=VBoxContainer.new(); column.size_flags_horizontal=Control.SIZE_EXPAND_FILL; bracket.add_child(column)
			UI.heading(column,{"quarter":"QUARTI","semi":"SEMIFINALI","final":"FINALE"}[stage],30)
			for f in games:
				var card=UI.card(column); UI.wrap(card,name_of(f.home)+"\n"+name_of(f.away),24); fixture_button(card,f)
	elif selected_comp in ["regular","playout"] or (selected_comp=="fifth" and info.get("mode","")=="group"):
		var standings=manager.standings(selected_comp)
		if not matches.is_empty():
			UI.table_header(list,["POS","SQUADRA","PT","G","V","P","SET +/−"],[54,650,95,95,95,95,180])
			for line in standings:
				var id=str(line.team_id)
				UI.table_row(list,[line.position,name_of(id),line.points,line.played,line.wins,line.losses,"%d/%d"%[line.sets_for,line.sets_against]],[54,650,95,95,95,95,180],func(): push("team",id),"comp-team-"+id)
		UI.heading(list,"CALENDARIO E RISULTATI",29)
		for f in matches:
			if selected_comp!="fifth" or f.get("stage","")=="group": fixture_button(list,f)
	if matches.is_empty():
		UI.wrap(list,"Il tabellone verrà composto dai risultati e dai criteri regolamentari della tua stagione. Nessuna qualificata viene inventata in anticipo.",26,UI.MUTED)
		UI.button(list,"TORNA ALLA STAGIONE",func(): show_tab(0),"home")
func squad_screen(team_id: String):
	var team=manager.team(team_id); UI.heading(page,"ROSA / "+team.get("name",""),40)
	if team_id==club(): UI.button(page,"FORMAZIONE, LIBERO E ROTAZIONE INIZIALE",func(): formation_screen(team_id),"formation")
	var list=UI.scroll(page)
	UI.table_header(list,["N°","GIOCATORE","RUOLO","GEN","CONDIZIONE","FORMA","DISPONIBILITÀ"],[50,475,64,82,145,100,390])
	for p in team.get("roster",[]):
		var player=p; var condition=manager.player_condition(p.id); var fatigue=float(condition.get("fatigue",0)); var injured=str(condition.get("injury_until",""))>=str(manager.state.date) and not str(condition.get("injury_until","")).is_empty()
		var availability="Recupero fino al "+condition.injury_until if injured else "Disponibile"
		var label="%2d   %-4s   %-31s   %3d       %3d%%                  %+d                 %s"%[int(p.get("jersey_number",0)),role(p.role),p.name,int(p.ratings.get("generale",0)),100-int(fatigue),int(condition.get("form",0)),availability]
		var b=UI.table_row(list,[str(int(p.get("jersey_number",0))),p.name,role(p.role),str(int(p.ratings.get("generale",0))),str(100-int(fatigue))+"%","%+d"%int(condition.get("form",0)),availability],[50,475,64,82,145,100,390],func(): push("player",player.id),"player-"+p.id)
		b.tooltip_text="Fatica %.0f/100. Recupero graduale nei giorni senza partite. Forma distinta dalla condizione."%fatigue
func role(value: String) -> String: return {"outside_hitter":"OH","opposite":"OPP","middle_blocker":"MB","setter":"S","libero":"L"}.get(value,value)
func formation_screen(team_id: String):
	var team=manager.team(team_id); var squad=manager.lineup(team_id)
	if squad.size()!=7: toast("Rosa non disponibile per una formazione regolare."); return
	modal_previous_key=focus_key(); modal=AcceptDialog.new(); modal.title="FORMAZIONE / "+team.name; modal.ok_button_text="SALVA FORMAZIONE"; modal.exclusive=true; modal.theme=theme.duplicate(true); add_child(modal)
	modal_dirty=false
	var box=VBoxContainer.new(); box.add_theme_constant_override("separation",8); modal.add_child(box); UI.label(box,"SESTETTO + LIBERO   ·   confronta condizione e valori prima di scegliere",19,UI.MUTED)
	var grid=GridContainer.new(); grid.columns=2; grid.add_theme_constant_override("h_separation",18); grid.add_theme_constant_override("v_separation",10); box.add_child(grid)
	var picks=[]; var options=[]
	for i in 7:
		var slot=i; var col=VBoxContainer.new(); grid.add_child(col)
		var candidates=team.roster.filter(func(p): return League.fits_slot(p.role,slot)); options.append(candidates)
		var slot_name=["OH1","MB1","OPP","OH2","MB2","S","L"][i]
		var labels=candidates.map(func(p): return "%s · %d · %s · GEN %d · COND %d%%"%[slot_name,int(p.jersey_number),p.name,int(p.ratings.get("generale",0)),100-int(manager.player_condition(p.id).fatigue)])
		var selected=0
		for j in candidates.size():
			if candidates[j].id==squad[i].id: selected=j
		var pick=UI.picker(col,labels,selected); pick.custom_minimum_size.x=470; pick.add_theme_font_size_override("font_size",19); picks.append(pick)
		pick.item_selected.connect(func(_i): modal_dirty=true)
	UI.label(box,"ROTAZIONE DI PARTENZA",20,UI.MUTED)
	var rotation=UI.picker(box,["P1 · S in 1","P6 · S in 6","P5 · S in 5","P4 · S in 4","P3 · S in 3","P2 · S in 2"],int(manager.state.lineups[team_id].rotation))
	rotation.item_selected.connect(func(_i): modal_dirty=true)
	UI.button(box,"RIPRISTINA FORMAZIONE BASE",func():
		var base=League.new().lineup(team)
		for i in mini(7,base.size()):
			for j in options[i].size():
				if options[i][j].id==base[i].id: picks[i].select(j)
		rotation.select(0))
	UI.button(box,"ANNULLA / CERCHIO",close_modal)
	modal.confirmed.connect(func():
		var ids=[]
		for i in 7: ids.append(options[i][picks[i].selected].id)
		if manager.set_lineup(team_id,ids,rotation.selected): modal_dirty=false; close_modal(); show_page(view,argument)
		else: toast(manager.error))
	modal.window_input.connect(modal_input); modal.popup_centered(Vector2i(mini(1080,get_viewport_rect().size.x-40),mini(680,get_viewport_rect().size.y-40))); picks[0].grab_focus()
func close_modal():
	if modal_dirty:
		confirm("Annullare le modifiche alla formazione?",func(): modal_dirty=false; close_modal()); return
	if modal!=null: modal.hide(); modal.queue_free(); modal=null
	focus_restore(modal_previous_key)
func modal_input(event):
	if modal==null: return
	var owner=modal.gui_get_focus_owner()
	if owner is OptionButton and owner.get_popup().visible: return
	if event.is_action_pressed("ui_cancel"): close_modal(); get_viewport().set_input_as_handled(); return
	for pair in [["ui_left",Vector2.LEFT],["ui_right",Vector2.RIGHT],["ui_up",Vector2.UP],["ui_down",Vector2.DOWN]]:
		if event.is_action_pressed(pair[0]): UI.navigate(modal,pair[1]); modal.set_input_as_handled(); return
func team_screen(id: String):
	var row=HBoxContainer.new(); page.add_child(row); UI.badge(row,id,100); var col=VBoxContainer.new(); row.add_child(col); UI.heading(col,name_of(id),43); UI.label(col,"Allenatore virtuale · SuperLega · "+season(),23,UI.MUTED)
	UI.button(row,"APRI LA ROSA",func(): push("roster-team",id),"roster-link")
	var panels=HBoxContainer.new(); panels.size_flags_vertical=Control.SIZE_EXPAND_FILL; page.add_child(panels)
	var roster=UI.card(panels,1000); UI.heading(roster,"I PROTAGONISTI",31); var list=UI.scroll(roster)
	for p in manager.team(id).roster:
		var player=p; UI.button(list,"%2d · %s · %s · GEN %d"%[int(p.jersey_number),role(p.role),p.name,int(p.ratings.get("generale",0))],func(): push("player",player.id),"player-"+p.id)
	var fixtures=UI.card(panels,760); var scroll=UI.scroll(fixtures)
	UI.heading(scroll,"IL RENDIMENTO",31)
	var table=manager.standings().filter(func(line): return str(line.team_id)==id)
	if not table.is_empty():
		var r=table[0]; UI.wrap(scroll,"%d gare · %d vittorie · %d sconfitte\nSet %d/%d · Punti %d/%d\nAce %s · Muri %s · Errori %s"%[r.played,r.wins,r.losses,r.sets_for,r.sets_against,r.points_for,r.points_against,str(r.aces) if r.aces!=null else "n.d.",str(r.blocks) if r.blocks!=null else "n.d.",str(r.errors) if r.errors!=null else "n.d."],22,UI.MUTED)
	UI.heading(scroll,"TROFEI DELLA CARRIERA",28)
	var trophies=0
	for archived in manager.state.get("archives",[]):
		for competition in archived.get("champions",{}):
			if str(archived.champions[competition])==id: UI.label(scroll,archived.season_label+" · "+COMPS.get(competition,competition),22,UI.GOLD); trophies+=1
	if trophies==0: UI.label(scroll,"Nessun trofeo ancora assegnato al club.",21,UI.MUTED)
	UI.heading(scroll,"CALENDARIO E RISULTATI",31)
	for f in state_fixtures():
		if f.home==id or f.away==id: fixture_button(scroll,f)
func squad_screen_detail(id: String):
	clear(page); squad_screen(id); call_deferred("focus_restore")
func player_screen(id: String):
	var p=manager.player(id); if p.is_empty(): UI.wrap(page,"Giocatore non disponibile."); return
	var team_id=""
	for t in manager.state.teams:
		if t.roster.any(func(member): return member.id==id): team_id=t.id; break
	var row=HBoxContainer.new(); row.size_flags_vertical=Control.SIZE_EXPAND_FILL; page.add_child(row)
	var profile_card=UI.card(row,665); var profile=UI.scroll(profile_card)
	var portrait=load("res://src/career_portrait.gd").new(); portrait.game=game; portrait.identity=p; portrait.kit=Kits.selection(team_id,"home",p.role=="libero"); profile.add_child(portrait)
	UI.label(profile,role(p.role)+" / #"+str(int(p.jersey_number)),24,UI.GOLD); UI.heading(profile,p.name,49); UI.wrap(profile,name_of(team_id),27,UI.MUTED)
	var c=manager.player_condition(id); UI.meter(profile,"CONDIZIONE · %d%%"%(100-int(c.fatigue)),100-float(c.fatigue)); UI.label(profile,"FORMA  %+d"%int(c.get("form",0)),29)
	UI.wrap(profile,"Infortunio simulato: "+str(c.injury_kind)+" · rientro "+str(c.injury_until) if not str(c.get("injury_until","")).is_empty() else "Disponibile per la prossima convocazione.",23,UI.MUTED)
	UI.button(profile,"SCHEDA SQUADRA",func(): push("team",team_id),"club-"+team_id)
	var detail=UI.card(row,1090); UI.heading(detail,"I SEI FONDAMENTALI",36)
	var skills=GridContainer.new(); skills.columns=2; skills.add_theme_constant_override("h_separation",30); skills.add_theme_constant_override("v_separation",15); detail.add_child(skills)
	for skill in ["battuta","ricezione","difesa","palleggio","schiacciata","muro"]:
		var field=UI.card(skills,485); UI.meter(field,skill.to_upper()+"  "+str(int(p.ratings.get(skill,0))),float(p.ratings.get(skill,0)))
	UI.heading(detail,"RENDIMENTO DELLA STAGIONE",31)
	var stats=manager.state.get("player_stats",{}).get(id,{})
	var data=UI.scroll(detail)
	for metric in [["appearances","Presenze"],["sets_played","Set giocati"],["points","Punti"],["attack_kills","Attacchi vincenti"],["attack_attempts","Attacchi tentati"],["aces","Ace"],["serve_errors","Errori in battuta"],["blocks","Muri punto"],["receptions","Ricezioni"],["digs","Difese"],["sets","Alzate"],["mvp","MVP"]]: UI.label(data,metric[1]+"   "+str(stats.get(metric[0],"Non disponibile")),22,UI.MUTED)
	UI.heading(data,"STORICO STAGIONI",29)
	for archive in manager.state.get("archives",[]):
		var historical=archive.get("player_stats",{}).get(id,{})
		if historical.is_empty(): continue
		var label_text=str(archive.get("season_label",archive.season))+" · "+str(historical.get("appearances",0))+" presenze · "+str(historical.get("points","n.d."))+" punti · "+str(historical.get("aces","n.d."))+" ace · "+str(historical.get("blocks","n.d."))+" muri"
		var year=str(archive.season); UI.button(data,label_text,func(): selected_stats_season=year; filter_team=team_id; selected_stats_role=p.role; push("statistiche"))
	UI.heading(data,"ULTIME PRESTAZIONI",29)
	var last_matches=state_fixtures().filter(func(f): return f.get("result",{}).get("players",{}).has(id)); last_matches.reverse()
	for f in last_matches.slice(0,5): fixture_button(data,f)
func stats_screen():
	UI.heading(page,"I NUMERI CHE RACCONTANO LA STAGIONE",40)
	var toolbar=HBoxContainer.new(); page.add_child(toolbar)
	var keys=["points","aces","blocks","attack_efficiency","reception_positive_pct","digs"]
	var pick=UI.picker(toolbar,["Punti","Ace","Muri punto","Efficienza attacco","Ricezione positiva","Difese"],maxi(0,keys.find(sort_stat)))
	pick.item_selected.connect(func(i): sort_stat=keys[i]; show_page(view))
	var comps=[""]+COMPS.keys(); var comp=UI.picker(toolbar,["Tutte le competizioni"]+COMPS.values(),maxi(0,comps.find(selected_stats_comp)))
	comp.item_selected.connect(func(i): selected_stats_comp=comps[i]; show_page(view))
	var teams=[""]+manager.state.teams.map(func(t): return t.id); var filter=UI.picker(toolbar,["Tutte le squadre"]+manager.state.teams.map(func(t): return t.name),maxi(0,teams.find(filter_team)))
	filter.item_selected.connect(func(i): filter_team=teams[i]; show_page(view))
	var extra=HBoxContainer.new(); page.add_child(extra)
	var seasons=[str(manager.state.season)]+manager.state.get("archives",[]).map(func(a): return str(a.season))
	var season_pick=UI.picker(extra,seasons.map(func(s): return "Stagione "+s+"/"+str(int(s)+1).right(2)),maxi(0,seasons.find(selected_stats_season)))
	season_pick.item_selected.connect(func(i): selected_stats_season=seasons[i]; selected_stats_match=""; show_page(view))
	var roles=["","outside_hitter","opposite","middle_blocker","setter","libero"]
	var role_pick=UI.picker(extra,["Tutti i ruoli","OH · Banda","OPP · Opposto","MB · Centrale","S · Palleggiatore","L · Libero"],maxi(0,roles.find(selected_stats_role)))
	role_pick.item_selected.connect(func(i): selected_stats_role=roles[i]; show_page(view))
	var scope=manager.state
	for archived in manager.state.get("archives",[]):
		if str(archived.season)==selected_stats_season: scope=archived; break
	var matches=scope.get("fixtures",[]).filter(func(f): return not f.get("result",{}).is_empty())
	var match_ids=[""]+matches.map(func(f): return str(f.id))
	var match_pick=UI.picker(extra,["Tutti gli incontri"]+matches.map(func(f): return f.scheduled_date+" · "+short(f.home)+"–"+short(f.away)),maxi(0,match_ids.find(selected_stats_match)))
	match_pick.item_selected.connect(func(i): selected_stats_match=match_ids[i]; show_page(view))
	UI.wrap(page,"Le partite giocate usano eventi misurati; le simulate producono stime dichiarate. I dati non misurabili restano non disponibili. Le percentuali richiedono un numero minimo di tentativi.",21,UI.MUTED)
	var list=UI.scroll(page); var leaders=manager.leaders(sort_stat,{"competition":selected_stats_comp,"team_id":filter_team,"season":selected_stats_season,"role":selected_stats_role,"match_id":selected_stats_match})
	if leaders.is_empty(): UI.wrap(list,"Nessun dato disponibile per questo filtro. I numeri inizieranno ad apparire dopo le prime partite.",26,UI.MUTED)
	for line in leaders:
		var id=str(line.get("player_id",line.get("id",""))); var p=manager.player(id)
		UI.table_row(list,[role(p.get("role","")),p.get("name",id),short(str(line.get("team_id",""))),"%.1f"%float(line.get("value",0)),str(line.get("stats_source",""))],[55,650,100,160,390],func(): push("player",id),"leader-"+id)
func news_screen():
	UI.heading(page,"DENTRO IL CAMPIONATO",42)
	var toolbar=HBoxContainer.new(); page.add_child(toolbar)
	var options=["Tutte le notizie","La mia squadra","Risultati","Infortuni e rientri","Coppe e playoff"]
	var pick=UI.picker(toolbar,options,int(argument) if str(argument).is_valid_int() else 0)
	pick.item_selected.connect(func(i): news_page=0; show_page("notizie",str(i)))
	UI.button(toolbar,"CERCA: "+(news_query if not news_query.is_empty() else "titolo o contenuto"),search_news,"search-news")
	UI.button(toolbar,"AZZERA RICERCA",func(): news_query=""; news_page=0; show_page("notizie",argument),"clear-search")
	var row=UI.scroll(page); var count=0
	for article in manager.state.get("news",[]):
		var item=article; var category=str(item.get("category","")); var clubs=item.get("clubs",item.get("teams",[]))
		if not news_query.is_empty() and not news_query.to_lower() in (str(item.get("title",""))+" "+str(item.get("body",""))).to_lower(): continue
		if pick.selected==1 and not club() in clubs and item.get("club_id","")!=club(): continue
		if pick.selected==2 and not category in ["result","results","postmatch"]: continue
		if pick.selected==3 and not category in ["injury","return","recovery"]: continue
		if pick.selected==4 and not item.get("competition","regular") in ["cup","supercup","playoff","fifth","playout"]: continue
		count+=1
		if count<=news_page*15 or count>(news_page+1)*15: continue
		var card=UI.card(row); var h=HBoxContainer.new(); card.add_child(h)
		var photo=image(h,"ball" if category in ["injury","return","recovery"] else ("net" if category in ["record","award"] else "arena"),145); photo.custom_minimum_size.x=285
		var text=VBoxContainer.new(); text.size_flags_horizontal=Control.SIZE_EXPAND_FILL; h.add_child(text)
		UI.label(text,str(item.get("date",manager.state.date))+"   /   "+category.to_upper(),19,UI.GOLD)
		UI.button(text,str(item.get("title","Notizia")),func(): push("article",str(item.get("id",""))),"article-"+str(item.get("id",count)))
		UI.wrap(text,str(item.get("subtitle",item.get("summary",""))),22,UI.MUTED)
	if count==0: UI.wrap(row,"Nessuna notizia per questo filtro.",25,UI.MUTED)
	var pages=HBoxContainer.new(); page.add_child(pages)
	var previous=UI.button(pages,"← PRECEDENTI",func(): news_page=maxi(0,news_page-1); show_page("notizie",argument)); previous.disabled=news_page==0
	UI.label(pages,"Pagina %d / %d"%[news_page+1,maxi(1,ceili(count/15.0))],22,UI.MUTED)
	var next=UI.button(pages,"SUCCESSIVE →",func(): news_page+=1; show_page("notizie",argument)); next.disabled=(news_page+1)*15>=count
func edit_text(initial: String,action: Callable):
	var previous=focus_key(); var target=LineEdit.new(); target.text=initial; add_child(target); target.hide(); host.clubs.open_keyboard(target)
	var keyboard=host.clubs.keyboard; var handlers={}
	handlers.accept=func():
		if keyboard.canceled.is_connected(handlers.cancel): keyboard.canceled.disconnect(handlers.cancel)
		var value=target.text; target.queue_free(); action.call(value); handlers.clear()
	handlers.cancel=func():
		if keyboard.confirmed.is_connected(handlers.accept): keyboard.confirmed.disconnect(handlers.accept)
		target.queue_free(); focus_restore(previous); handlers.clear()
	keyboard.confirmed.connect(handlers.accept,CONNECT_ONE_SHOT); keyboard.canceled.connect(handlers.cancel,CONNECT_ONE_SHOT)
func search_news():
	edit_text(news_query,func(value): news_query=value; news_page=0; show_page("notizie",argument))
func article_screen(id: String):
	var matches=manager.state.get("news",[]).filter(func(n): return str(n.get("id",""))==id)
	if matches.is_empty(): UI.wrap(page,"Articolo non disponibile."); return
	var article=matches[0]; var row=HBoxContainer.new(); row.size_flags_vertical=Control.SIZE_EXPAND_FILL; page.add_child(row)
	var art=UI.card(row,780); image(art,"net" if article.get("category")=="record" else "arena",420)
	UI.label(art,str(article.get("date",""))+" / "+str(article.get("category","")).to_upper(),22,UI.GOLD)
	var copy=UI.card(row,990); var scroll=UI.scroll(copy); UI.heading(scroll,article.get("title",""),43)
	UI.wrap(scroll,article.get("subtitle",article.get("summary","")),27,UI.GOLD); UI.wrap(scroll,article.get("body",""),26)
	UI.wrap(scroll,"Contenuto generato dai risultati della carriera. Eventuali dichiarazioni sono commenti virtuali, non dichiarazioni reali.",21,UI.MUTED)
	var involved=article.get("clubs",article.get("teams",[])).duplicate()
	if involved.is_empty() and not str(article.get("club_id","")).is_empty(): involved.append(article.club_id)
	for team_id in involved:
		var id_team=str(team_id); UI.button(scroll,"SQUADRA / "+name_of(id_team),func(): push("team",id_team))
	for player_id in article.get("players",[]):
		var pid=str(player_id); UI.button(scroll,"GIOCATORE / "+manager.player(pid).get("name",pid),func(): push("player",pid))
func archive_screen():
	UI.heading(page,"UNA STORIA CHE RIMANE",43)
	UI.wrap(page,"Albo d'oro, premi e risultati congelati a fine stagione. Le qualificazioni europee sono riconoscimenti: nessuna coppa europea viene simulata.",22,UI.MUTED)
	var archives=manager.state.get("archives",[])
	if archives.is_empty():
		UI.wrap(page,"L'archivio inizierà al termine della prima stagione.",26,UI.MUTED); UI.button(page,"TORNA ALLA STAGIONE",func(): show_tab(0)); return
	archive_index=clampi(archive_index,0,archives.size()-1)
	var pick=UI.picker(page,archives.map(func(a): return a.get("season_label",str(a.season))),archive_index)
	pick.item_selected.connect(func(i): archive_index=i; show_page(view))
	var data=archives[archive_index]; var list=UI.scroll(page)
	var row=HBoxContainer.new(); list.add_child(row)
	var winners=UI.card(row); UI.heading(winners,"ALBO D'ORO",31)
	for competition in data.get("champions",{}):
		var id=str(data.champions[competition]); UI.button(winners,COMPS.get(competition,competition)+"  ·  "+name_of(id),func(): push("team",id))
	var awards=UI.card(row); UI.heading(awards,"PREMI INDIVIDUALI",31)
	for key in data.get("awards",{}):
		var award=data.awards[key]; var pid=str(award.get("player_id",""))
		UI.button(awards,{"points":"Punti","aces":"Ace","blocks":"Muri","digs":"Difese"}.get(key,key)+" · "+manager.player(pid).get("name",pid)+" · "+str(int(award.get("value",0))),func(): push("player",pid))
	UI.button(awards,"STATISTICHE DELLA STAGIONE",func(): selected_stats_season=str(data.season); push("statistiche"))
	UI.heading(list,"RICONOSCIMENTI EUROPEI",30)
	var europe=data.get("european_recognition",{})
	for key in ["champions_league","cev_cup","challenge_cup"]:
		var ids=europe.get(key,[]); if ids is String: ids=[ids]
		for team_id in ids:
			var id=str(team_id)
			if not id.is_empty(): UI.button(list,{"champions_league":"Champions League","cev_cup":"CEV Cup","challenge_cup":"Challenge Cup"}[key]+" · "+name_of(id),func(): push("team",id))
	UI.heading(list,"CLASSIFICA FINALE",30)
	for line in data.get("standings",[]):
		var id=str(line.get("team_id","")); UI.table_row(list,[line.get("position",0),name_of(id),str(line.get("points",0))+" PT"],[54,700,160],func(): push("team",id),"archive-club-"+id)
	UI.heading(list,"RECORD DELLA CARRIERA",30)
	for key in manager.state.get("records",{}):
		var record=manager.state.records[key]; var pid=str(record.get("player_id",""))
		UI.button(list,{"points":"Punti","aces":"Ace","blocks":"Muri","digs":"Difese"}.get(key,key)+" · "+manager.player(pid).get("name",pid)+" · "+str(int(record.get("value",0)))+" / "+str(record.get("season","")),func(): push("player",pid))
	UI.heading(list,"TUTTI I RISULTATI",30)
	for f in data.get("fixtures",[]): fixture_button(list,f)
func options_screen():
	UI.heading(page,"LE REGOLE DELLA TUA CARRIERA",42); var row=HBoxContainer.new(); row.size_flags_vertical=Control.SIZE_EXPAND_FILL; page.add_child(row)
	var explanation=UI.card(row,760); image(explanation,"court",300); UI.heading(explanation,"SCELTE TRASPARENTI",37)
	UI.wrap(explanation,"Con la fatica disattivata non si applicano penalità nascoste di condizione. Con i valori giocatori disattivati resta il percorso originale delle abilità.\n\nGli infortuni sono eventi simulati della carriera e non fatti reali.\n\nI salvataggi restano in locale e non vengono sostituiti dagli aggiornamenti.",25,UI.MUTED)
	var card=UI.card(row,1015); var scroll=UI.scroll(card); var controls=options_controls(scroll,manager.state.options)
	dirty_options=false
	UI.button(scroll,"APPLICA E SALVA",func():
		manager.update_options(read_options(controls)); dirty_options=false
		toast("Impostazioni salvate" if manager.save() else manager.error),"save-options")
	UI.button(scroll,"IMPORTA MODIFICHE DATABASE LOCALE",func(): confirm("Importare le tue modifiche da Modifica? Risultati e stato fisico restano conservati; controlla poi la formazione.",func(): toast("Rosa aggiornata" if manager.import_roster_edits() else manager.error)),"import-roster")
func prematch_screen():
	var fixture=manager.next_fixture(); if fixture.is_empty(): show_tab(0); return
	UI.heading(page,"PREPARA LA PARTITA",43)
	UI.label(page,fixture.scheduled_date+"  /  "+COMPS.get(fixture.competition,fixture.competition)+"  /  "+("IN CASA" if fixture.home==club() else "IN TRASFERTA"),23,UI.GOLD)
	var row=HBoxContainer.new(); row.size_flags_vertical=Control.SIZE_EXPAND_FILL; page.add_child(row)
	for side in 2:
		var team_id=club() if side==0 else (fixture.away if fixture.home==club() else fixture.home); var team=manager.team(team_id)
		var card=UI.card(row,890); var title=HBoxContainer.new(); card.add_child(title); UI.badge(title,team_id,72); UI.heading(title,team.name,33)
		var index=side; var select=UI.picker(card,["Casa","Trasferta"],0 if chosen_kits[side]=="home" else 1)
		var preview=load("res://src/kit_preview.gd").new(); card.add_child(preview); preview.custom_minimum_size.y=215; preview.show_kit(team_id,chosen_kits[side])
		select.item_selected.connect(func(i): chosen_kits[index]="home" if i==0 else "away"; preview.show_kit(team_id,chosen_kits[index]))
		if side==0: UI.button(card,"FORMAZIONE E ROTAZIONE",func(): formation_screen(team_id),"prematch-formation")
		var list=UI.scroll(card)
		for p in manager.lineup(team_id):
			var player=p; var c=manager.player_condition(p.id)
			UI.button(list,"%s · %s  /  GEN %d  ·  COND %d%%  ·  FORMA %+d"%[role(p.role),p.name,int(p.ratings.get("generale",0)),100-int(c.fatigue),int(c.form)],func(): push("player",player.id),"prematch-"+p.id)
	var buttons=HBoxContainer.new(); page.add_child(buttons); UI.button(buttons,"SCENDI IN CAMPO",launch_match,"launch"); UI.button(buttons,"SIMULA PARTITA",simulate_match,"simulate")
func launch_match():
	var fixture=manager.next_fixture(); if fixture.is_empty(): return
	if not manager.prepare_match(str(fixture.id)): toast(manager.error); return
	var away=fixture.home!=club(); var ids=[club(),fixture.home if away else fixture.away]; var squads=[]; var teams=[]
	for side in 2:
		var t=manager.team(ids[side]); var squad=manager.lineup(ids[side]); teams.append(t); squads.append(squad)
		if squad.size()!=7: toast("Formazione non disponibile: controlla ruoli e indisponibili."); return
		game.team_names[side]=t.name
		for i in 6: game.players[side*6+i].set_roster_identity(squad[i],squad[6],Kits.selection(t.id,chosen_kits[side]),Kits.selection(t.id,chosen_kits[side],true))
	game.use_player_stats=bool(manager.state.options.get("use_player_stats",false)); game.match_best_of=5; game.match_points=25; game.difficulty=int(manager.state.options.get("difficulty",1))
	if game.get("match_management")!=null:
		var options=manager.state.options.duplicate(true); options.date=manager.state.date; options.career_form=true
		if not game.match_management.configure_rosters(teams,squads,manager.state.conditions,options): toast("Rosa insufficiente o giocatori indisponibili: correggi la formazione."); return
		if not game.match_management.match_completed.is_connected(match_completed): game.match_management.match_completed.connect(match_completed)
	game.scores=[0,0]; game.sets=[0,0]; game.rotations=[manager.state.lineups[ids[0]].rotation,manager.state.lineups[ids[1]].rotation]; game.server=1 if away else 0
	game.paused=false; game.match_finished=false; game.demo=false; game.gallery=false; game.camera_mode=0; game.set_camera(); game.reset_rally(); game.started=true
	active_fixture=fixture.duplicate(true); pending_post.clear(); hide(); host.play_hub.hide(); host.clubs.hide(); host.clubs.music.stop()
func match_completed(result: Dictionary):
	if active_fixture.is_empty(): return
	var output=result.duplicate(true); var away=active_fixture.home!=club()
	if away:
		output.sets=[result.sets[1],result.sets[0]]; output.set_scores=[]
		for score in result.set_scores: output.set_scores.append([score[1],score[0]])
		if result.get("team_stats",[]).size()==2: output.team_stats=[result.team_stats[1],result.team_stats[0]]
	output.home=active_fixture.home; output.away=active_fixture.away; output.fixture_id=active_fixture.id; output.stats_source="measured"
	if manager.record_played_result(str(active_fixture.id),output): pending_post={"fixture_id":active_fixture.id}
	else: pending_post={"error":manager.error}
	active_fixture.clear()
func result_screen(id: String):
	var fixtures=state_fixtures().filter(func(f): return str(f.id)==id)
	if fixtures.is_empty():
		for archive in manager.state.get("archives",[]):
			fixtures=archive.get("fixtures",[]).filter(func(f): return str(f.id)==id)
			if not fixtures.is_empty(): break
	if fixtures.is_empty(): UI.wrap(page,"Partita non disponibile."); return
	var fixture=fixtures[0]; var result=fixture.get("result",{})
	UI.heading(page,COMPS.get(fixture.competition,fixture.competition).to_upper()+" / "+str(fixture.scheduled_date),38)
	var row=HBoxContainer.new(); page.add_child(row); UI.badge(row,fixture.home,115); UI.heading(row,name_of(fixture.home),38)
	UI.heading(row,"—" if result.is_empty() else "%d  –  %d"%[int(result.sets[0]),int(result.sets[1])],65)
	UI.heading(row,name_of(fixture.away),38); UI.badge(row,fixture.away,115)
	var buttons=HBoxContainer.new(); page.add_child(buttons); UI.button(buttons,"SCHEDA CASA",func(): push("team",str(fixture.home))); UI.button(buttons,"SCHEDA OSPITI",func(): push("team",str(fixture.away)))
	if result.is_empty():
		UI.wrap(page,"Incontro ancora da disputare. Nessun risultato reale è stato importato.",27,UI.MUTED)
		if fixture.home==club() or fixture.away==club(): UI.button(page,"TORNA AL MATCH CENTER",func(): show_tab(0),"match-center")
		return
	UI.label(page,"PARZIALI   "+"   /   ".join(result.get("set_scores",[]).map(func(s): return "%d–%d"%[s[0],s[1]])),31,UI.GOLD)
	UI.label(page,"Eventi misurati dal gameplay" if result.get("stats_source","")=="measured" else "Tabellino stimato dal simulatore",22,UI.MUTED)
	var mvp=str(result.get("mvp",""))
	if not mvp.is_empty(): UI.button(page,"MVP / "+manager.player(mvp).get("name",mvp),func(): push("player",mvp),"mvp")
	var list=UI.scroll(page)
	for player_id in result.get("players",{}):
		var pid=str(player_id); var p=manager.player(pid); var data=result.players[pid]
		UI.button(list,p.get("name",pid)+"   ·   Punti "+str(data.get("points","n.d."))+"   ·   Ace "+str(data.get("aces","n.d."))+"   ·   Muri "+str(data.get("blocks","n.d.")),func(): push("player",pid),"result-"+pid)
	if not result.get("point_log",[]).is_empty(): UI.button(page,"RIVEDI LA CRONACA PUNTO PER PUNTO",func(): point_log_dialog(result),"point-log")
	UI.button(page,"CONTINUA LA STAGIONE",func(): stack.clear(); show_tab(0),"continue-season")
func point_log_dialog(result: Dictionary):
	modal_previous_key=focus_key(); modal_dirty=false; modal=AcceptDialog.new(); modal.title="CRONACA / SIMULAZIONE DETTAGLIATA"; modal.theme=theme; add_child(modal)
	var box=VBoxContainer.new(); modal.add_child(box); box.custom_minimum_size=Vector2(750,460); var list=UI.scroll(box)
	for point in result.point_log:
		var score=point.get("score",[0,0]); var side=int(point.get("winner",0)); var id=str(result.home) if side==0 else str(result.away)
		UI.button(list,"SET %s  ·  %s–%s  ·  %s  /  %s"%[point.get("set",1),score[0],score[1],short(id),str(point.get("action",""))],func(): push("team",id); close_modal())
	modal.confirmed.connect(close_modal); modal.window_input.connect(modal_input); modal.popup_centered(Vector2i(820,570)); modal.get_ok_button().grab_focus()
func _process(dt):
	if not game.started and not pending_post.is_empty():
		host.play_hub.hide(); host.clubs.hide(); show()
		var result=pending_post.duplicate(); pending_post.clear(); stack.clear()
		if result.has("error"): show_tab(0); toast(result.error)
		else: show_page("result",str(result.fixture_id))
	elif not game.started and not active_fixture.is_empty():
		active_fixture.clear(); show_tab(0); toast("Partita interrotta: l'incontro è ancora da disputare.")
	if not visible or (modal!=null and modal.visible): return
	for child in get_children():
		if child is Window and child.visible: return
	var focused=get_viewport().gui_get_focus_owner()
	if focused is OptionButton and focused.get_popup().visible: return
	var pad=game.pad()
	if pad>=0:
		var scroll_axis=Input.get_joy_axis(pad,JOY_AXIS_RIGHT_Y)
		if absf(scroll_axis)>.25:
			var sc=focused
			while sc!=null and not sc is ScrollContainer: sc=sc.get_parent()
			if sc==null:
				var scrolls=page.find_children("*","ScrollContainer",true,false)
				if not scrolls.is_empty(): sc=scrolls[0]
			if sc is ScrollContainer: sc.scroll_vertical+=roundi(scroll_axis*700*dt)
	axis_wait-=dt
	var axis=Vector2(Input.get_action_strength("ui_right")-Input.get_action_strength("ui_left"),Input.get_action_strength("ui_down")-Input.get_action_strength("ui_up"))
	if axis.length()>.65 and axis_wait<=0:
		var direction=Vector2(signf(axis.x),0) if absf(axis.x)>absf(axis.y) else Vector2(0,signf(axis.y))
		if direction==held_direction: UI.navigate(self,direction)
		else: held_direction=direction
		axis_wait=.12
	elif axis.length()<.25: held_direction=Vector2.ZERO
func _input(event):
	if not visible: return
	if host.clubs.keyboard!=null and host.clubs.keyboard.visible: return
	if modal!=null and modal.visible: return
	for child in get_children():
		if child is Window and child.visible: return
	var owner=get_viewport().gui_get_focus_owner()
	if owner is OptionButton and owner.get_popup().visible: return
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.physical_keycode==KEY_ESCAPE): back(); get_viewport().set_input_as_handled(); return
	if event.is_action_pressed("start") or (event is InputEventKey and event.pressed and event.physical_keycode==KEY_F5):
		if not manager.state.is_empty(): saved_focus=focus_key(); toast("Carriera salvata" if manager.save() else manager.error)
		get_viewport().set_input_as_handled(); return
	if event is InputEventJoypadButton and event.pressed:
		if event.button_index in [JOY_BUTTON_LEFT_SHOULDER,JOY_BUTTON_RIGHT_SHOULDER] and not manager.state.is_empty(): show_tab(tab_index+(-1 if event.button_index==JOY_BUTTON_LEFT_SHOULDER else 1)); get_viewport().set_input_as_handled(); return
		if event.button_index==JOY_BUTTON_X and view in ["home","prematch"]: simulate_match(); get_viewport().set_input_as_handled(); return
	if event is InputEventJoypadMotion and event.axis in [JOY_AXIS_TRIGGER_LEFT,JOY_AXIS_TRIGGER_RIGHT] and event.axis_value>.7 and view=="calendario" and axis_wait<=0:
		round_index=clampi(round_index+(-1 if event.axis==JOY_AXIS_TRIGGER_LEFT else 1),0,21); show_page(view); axis_wait=.3; get_viewport().set_input_as_handled(); return
	if event is InputEventKey and event.pressed:
		if event.physical_keycode in [KEY_PAGEUP,KEY_PAGEDOWN] and not manager.state.is_empty(): show_tab(tab_index+(-1 if event.physical_keycode==KEY_PAGEUP else 1)); get_viewport().set_input_as_handled(); return
		if event.physical_keycode==KEY_Q and view in ["home","prematch"]: simulate_match(); get_viewport().set_input_as_handled(); return
	for pair in [["ui_left",Vector2.LEFT],["ui_right",Vector2.RIGHT],["ui_up",Vector2.UP],["ui_down",Vector2.DOWN]]:
		if event.is_action_pressed(pair[0]): UI.navigate(self,pair[1]); held_direction=pair[1]; axis_wait=.32; get_viewport().set_input_as_handled(); return

