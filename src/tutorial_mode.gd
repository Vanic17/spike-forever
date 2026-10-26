extends CanvasLayer
## Isolated practice orchestration. Uses production contacts, input, poses and flight.
const Lessons=preload("res://src/tutorial_lessons.gd")
var game
var host
var active:=false
var category:="serve"
var lesson_index:=0
var successes:=0
var attempts:=0
var free_practice:=false
var exercise: Dictionary={}
var progress: Dictionary={}
var saved: Dictionary={}
var pending:=""
var pending_ok:=false
var retry_at:=0.0
var began_at:=0.0
var performed: Dictionary={}
var max_move:=0.0
var server_origin:=Vector3.ZERO
var jump_seen:=0
var jump_members:=0
var jump_left:=false
var jump_right:=false
var menu: Control
var categories: Array[Button]=[]
var lesson_pick: OptionButton
var start_button: Button
var back_button: Button
var menu_title: Label
var menu_subtitle: Label
var detail_title: Label
var detail: RichTextLabel
var progress_label: Label
var diagram
var coach: PanelContainer
var coach_title: Label
var coach_body: Label
var coach_result: Label
var coach_counter: Label
var coach_hint: Label
var modal: Control
var modal_title: Label
var modal_body: Label
var modal_buttons: Array[Button]=[]
var modal_intro:=false
var target: Node3D
var target_label: Label3D
var last_camera:=0
var feed_ready_at:=-1.0
var feed_point:=Vector3.ZERO
var staged_hitter:=-1
var staged_stance:=Vector3.ZERO
var paused_charge:=false

func txt(it: String,en: String) -> String: return Lessons.say(it,en)
func _ready():
	layer=22
	theme_setup()
	build_menu()
	build_coach()
	build_modal()
	load_progress()
	menu.hide(); coach.hide(); modal.hide()

func theme_setup():
	# Shared within this CanvasLayer only: no changes to the rest of the UI.
	var theme=Theme.new(); theme.default_font_size=18
	var normal=box(Color("172b40"),Color("36516b"),10)
	var focused=box(Color("23465c"),Color("ebca80"),10)
	for kind in ["normal","disabled"]: theme.set_stylebox(kind,"Button",normal)
	for kind in ["hover","pressed","focus","hover_pressed"]: theme.set_stylebox(kind,"Button",focused)
	theme.set_color("font_color","Button",Color("ecf0f5"))
	theme.set_color("font_focus_color","Button",Color("ffe1a4"))
	theme.set_color("font_disabled_color","Button",Color("617082"))
	set_meta("ui_theme",theme)

func box(color: Color,border: Color=Color("29445b"),radius: int=12) -> StyleBoxFlat:
	var style=StyleBoxFlat.new(); style.bg_color=color; style.border_color=border; style.set_border_width_all(1); style.set_corner_radius_all(radius)
	style.content_margin_left=18; style.content_margin_right=18; style.content_margin_top=12; style.content_margin_bottom=12
	return style

func surface() -> Control:
	var value=Control.new(); add_child(value); value.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); value.theme=get_meta("ui_theme")
	return value

func label(parent: Node,text: String,px: int=18,color: Color=Color("eff3f8")) -> Label:
	var node=Label.new(); node.text=text; node.add_theme_font_size_override("font_size",px); node.add_theme_color_override("font_color",color); parent.add_child(node); return node

func button(parent: Node,text: String,action: Callable) -> Button:
	var value=Button.new(); value.text=text; value.custom_minimum_size.y=46; value.size_flags_horizontal=Control.SIZE_EXPAND_FILL; parent.add_child(value); value.pressed.connect(action); return value

func margins(parent: Control,amount: int) -> MarginContainer:
	var m=MarginContainer.new(); parent.add_child(m); m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left","right","top","bottom"]: m.add_theme_constant_override("margin_"+edge,amount)
	return m

func build_menu():
	menu=surface()
	var bg=ColorRect.new(); bg.color=Color("081320"); menu.add_child(bg); bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var column=VBoxContainer.new(); column.add_theme_constant_override("separation",14); margins(menu,28).add_child(column)
	var header=HBoxContainer.new(); column.add_child(header)
	var titles=VBoxContainer.new(); titles.size_flags_horizontal=Control.SIZE_EXPAND_FILL; header.add_child(titles)
	menu_title=label(titles,"",32,Color("ebca80")); menu_subtitle=label(titles,"",15,Color("acbdcd")); menu_subtitle.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	back_button=button(header,"",close_menu); back_button.custom_minimum_size.x=210; back_button.size_flags_horizontal=Control.SIZE_SHRINK_END
	var content=HBoxContainer.new(); content.add_theme_constant_override("separation",22); content.size_flags_vertical=Control.SIZE_EXPAND_FILL; column.add_child(content)
	var left=VBoxContainer.new(); left.add_theme_constant_override("separation",10); left.custom_minimum_size.x=255; content.add_child(left)
	for i in Lessons.categories().size():
		var index: int=i
		var item=button(left,"",func(): select_category(index); lesson_pick.grab_focus())
		item.custom_minimum_size.y=64; item.alignment=HORIZONTAL_ALIGNMENT_LEFT; item.add_theme_font_size_override("font_size",17)
		item.focus_entered.connect(func(): select_category(index))
		categories.append(item)
	var panel=PanelContainer.new(); panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL; panel.add_theme_stylebox_override("panel",box(Color("102235"))); content.add_child(panel)
	var right=VBoxContainer.new(); right.add_theme_constant_override("separation",10); panel.add_child(right)
	detail_title=label(right,"",25)
	detail_title.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	diagram=preload("res://src/tutorial_diagram.gd").new(); diagram.custom_minimum_size.y=112; diagram.size_flags_vertical=Control.SIZE_EXPAND_FILL; right.add_child(diagram)
	lesson_pick=OptionButton.new(); lesson_pick.custom_minimum_size.y=44; lesson_pick.fit_to_longest_item=false; right.add_child(lesson_pick)
	lesson_pick.item_selected.connect(func(index): lesson_index=index; refresh_detail())
	detail=RichTextLabel.new(); detail.fit_content=true; detail.scroll_active=false; detail.bbcode_enabled=false; detail.custom_minimum_size.y=100; detail.add_theme_font_size_override("normal_font_size",16); right.add_child(detail)
	progress_label=label(right,"",14,Color("7bd4ce"))
	start_button=button(right,"",func(): start_lesson(category,lesson_pick.selected))
	for i in categories.size():
		categories[i].focus_neighbor_top=categories[i].get_path_to(back_button if i==0 else categories[i-1])
		categories[i].focus_neighbor_bottom=categories[i].get_path_to(categories[mini(i+1,categories.size()-1)])
		categories[i].focus_neighbor_right=categories[i].get_path_to(lesson_pick)
		categories[i].focus_neighbor_left=categories[i].get_path_to(categories[i])
		categories[i].focus_next=categories[i].get_path_to(lesson_pick)
	lesson_pick.focus_neighbor_left=lesson_pick.get_path_to(categories[0]); lesson_pick.focus_neighbor_bottom=lesson_pick.get_path_to(start_button); lesson_pick.focus_neighbor_top=lesson_pick.get_path_to(back_button)
	start_button.focus_neighbor_top=start_button.get_path_to(lesson_pick); start_button.focus_neighbor_left=start_button.get_path_to(categories[0]); start_button.focus_neighbor_right=start_button.get_path_to(back_button); start_button.focus_neighbor_bottom=start_button.get_path_to(back_button)
	back_button.focus_neighbor_bottom=back_button.get_path_to(categories[0]); back_button.focus_neighbor_left=back_button.get_path_to(start_button)
	lesson_pick.focus_next=lesson_pick.get_path_to(start_button); start_button.focus_next=start_button.get_path_to(back_button); back_button.focus_next=back_button.get_path_to(categories[0])

func refresh_menu_text():
	menu_title.text=txt("TUTORIAL / TRAINING CENTER","TUTORIAL / TRAINING CENTER")
	menu_subtitle.text=txt("35 lezioni libere · progressi salvati su questo PC · nessun requisito di sblocco","35 freely available lessons · progress saved on this PC · no unlock requirements")
	back_button.text=txt("INDIETRO · B / CERCHIO","BACK · B / CIRCLE")
	start_button.text=txt("ENTRA IN CAMPO  ›","ENTER THE COURT  ›")
	var data=Lessons.categories()
	for i in data.size(): categories[i].text=data[i].tag+"   "+data[i].name

func open(from):
	host=from
	var previous_lesson:=lesson_index
	if active: restore()
	refresh_menu_text(); menu.show(); coach.hide(); modal.hide()
	var index:=0
	for i in Lessons.categories().size():
		if Lessons.categories()[i].id==category: index=i
	select_category(index); lesson_pick.select(clampi(previous_lesson,0,lesson_pick.item_count-1)); refresh_detail(); categories[index].grab_focus()

func close_menu():
	menu.hide()
	if is_instance_valid(host): host.tutorial_button.grab_focus()

func select_category(index: int):
	var cat: Dictionary=Lessons.categories()[index]
	var changed: bool=category!=cat.id or lesson_pick.item_count==0
	category=cat.id; diagram.category=category; diagram.accent=cat.color; diagram.queue_redraw(); detail_title.text=cat.name+"  /  "+cat.subtitle
	if changed:
		lesson_index=0; lesson_pick.clear()
		var lessons=Lessons.all(category)
		for i in lessons.size(): lesson_pick.add_item("%02d  ·  %s"%[i+1,lessons[i].title])
		lesson_pick.select(0)
	lesson_pick.focus_neighbor_left=lesson_pick.get_path_to(categories[index]); start_button.focus_neighbor_left=start_button.get_path_to(categories[index])
	refresh_detail()

func refresh_detail():
	var lessons=Lessons.all(category)
	if lessons.is_empty(): return
	lesson_index=clampi(lesson_pick.selected,0,lessons.size()-1)
	var item: Dictionary=lessons[lesson_index]
	detail.text=item.body
	var done:=int(progress.get(category+":"+item.id,0))
	progress_label.text=txt("Completata · ripetibile liberamente","Completed · freely repeatable") if done>=int(item.goal) else txt("Obiettivo: 2 esecuzioni riuscite · scegli qualsiasi lezione","Goal: 2 successful attempts · choose any lesson")

func capture():
	if not saved.is_empty(): return
	for key in ["scores","sets","rotations","team_names"]: saved[key]=game.get(key).duplicate()
	for key in ["server","match_best_of","match_points","camera_mode","difficulty","clock_time","attack_serial","shot_serial","rally_serial"]: saved[key]=game.get(key)
	saved.visibility=[]
	for p in game.players: saved.visibility.append(p.visible)
	saved.rng_seed=game.rng.seed; saved.rng_state=game.rng.state

func restore():
	active=false; coach.hide(); modal.hide()
	if is_instance_valid(target): target.hide()
	game.started=false; game.paused=false
	if not saved.is_empty():
		for key in ["scores","sets","rotations","team_names","server","match_best_of","match_points","camera_mode","difficulty","clock_time","attack_serial","shot_serial","rally_serial"]: game.set(key,saved[key])
		game.rng.seed=saved.rng_seed; game.rng.state=saved.rng_state
		for i in game.players.size(): game.players[i].visible=saved.visibility[i]
		saved.clear()
	game.charging=false; game.armed=false; game.reset_rally(); game.set_camera()

func home():
	restore(); menu.hide(); game.return_to_main_menu()
	if is_instance_valid(host): host.tutorial_button.grab_focus()

func start_lesson(id: String,index: int):
	capture(); category=id; lesson_index=clampi(index,0,Lessons.all(id).size()-1); exercise=Lessons.all(id)[lesson_index]
	active=true; successes=0; attempts=0; free_practice=false; pending=""; menu.hide(); coach.show()
	game.camera_mode=0; game.set_camera(); game.demo=false; game.started=true
	prepare_attempt(); show_modal(true)

func build_coach():
	var shell=surface(); shell.mouse_filter=Control.MOUSE_FILTER_IGNORE
	coach=PanelContainer.new(); shell.add_child(coach); coach.position=Vector2(20,20); coach.custom_minimum_size=Vector2(370,0); coach.size.x=370; coach.mouse_filter=Control.MOUSE_FILTER_IGNORE
	coach.add_theme_stylebox_override("panel",box(Color("0b1d2ce8"),Color("bd9b59")))
	var body=VBoxContainer.new(); body.mouse_filter=Control.MOUSE_FILTER_IGNORE; body.add_theme_constant_override("separation",7); coach.add_child(body)
	coach_title=label(body,"",20,Color("f0cb7b"))
	coach_counter=label(body,"",14,Color("80dcd3"))
	coach_body=label(body,"",15,Color("c4d3e0")); coach_body.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; coach_body.custom_minimum_size.x=320
	coach_result=label(body,"",17); coach_result.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	coach_hint=label(body,"",13,Color("92aabc")); coach_hint.text="Options / Menu / Esc · "+txt("lezioni e pausa","lessons & pause")
	for node in body.get_children(): node.mouse_filter=Control.MOUSE_FILTER_IGNORE

func update_coach():
	coach_title.text=Lessons.categories()[category_index()].name+" · %02d/%02d"%[lesson_index+1,Lessons.all(category).size()]
	coach_counter.text=(txt("ALLENAMENTO LIBERO","FREE PRACTICE")+" · " if free_practice else "")+txt("Riuscite: %d / 2  ·  Tentativi: %d","Successes: %d / 2  ·  Attempts: %d")%[successes,attempts]
	coach_body.text=exercise.title+"\n"+exercise.body
	coach_hint.text="Options / Menu / Esc · "+txt("lezioni e pausa","lessons & pause")
	coach_result.text=pending if not pending.is_empty() else txt("Preparati: prova il comando indicato.","Get ready: try the indicated control.")
	coach_result.modulate=Color("79e0bc") if pending_ok else Color("e9c781")

func category_index() -> int:
	var cats=Lessons.categories()
	for i in cats.size():
		if cats[i].id==category: return i
	return 0

func build_modal():
	modal=surface()
	var shade=ColorRect.new(); shade.color=Color("050d18e8"); modal.add_child(shade); shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var centre=CenterContainer.new(); margins(modal,24).add_child(centre)
	var card=PanelContainer.new(); card.custom_minimum_size.x=720; card.add_theme_stylebox_override("panel",box(Color("11273d"),Color("dfbc73"))); centre.add_child(card)
	var body=VBoxContainer.new(); body.add_theme_constant_override("separation",16); card.add_child(body)
	modal_title=label(body,"",27,Color("edca80"))
	modal_title.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	modal_body=label(body,"",17); modal_body.custom_minimum_size.x=660; modal_body.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	var grid=GridContainer.new(); grid.columns=2; grid.add_theme_constant_override("h_separation",12); grid.add_theme_constant_override("v_separation",10); body.add_child(grid)
	modal_buttons.append(button(grid,"",resume))
	modal_buttons.append(button(grid,"",func(): prepare_attempt(); resume()))
	modal_buttons.append(button(grid,"",func(): start_lesson(category,lesson_index-1)))
	modal_buttons.append(button(grid,"",func():
		if lesson_index+1<Lessons.all(category).size(): start_lesson(category,lesson_index+1)
		else: open(host)))
	modal_buttons.append(button(grid,"",func(): open(host)))
	modal_buttons.append(button(grid,"",home))
	for i in modal_buttons.size():
		var b=modal_buttons[i]
		b.focus_neighbor_left=b.get_path_to(modal_buttons[i-1 if i%2==1 else i]); b.focus_neighbor_right=b.get_path_to(modal_buttons[i+1 if i%2==0 else i])
		b.focus_neighbor_top=b.get_path_to(modal_buttons[maxi(0,i-2)]); b.focus_neighbor_bottom=b.get_path_to(modal_buttons[mini(5,i+2)])
		b.focus_next=b.get_path_to(modal_buttons[(i+1)%6]); b.focus_previous=b.get_path_to(modal_buttons[posmod(i-1,6)])

func show_modal(intro: bool=false):
	modal_intro=intro; paused_charge=game.charging; game.paused=true; coach.hide(); modal.show()
	modal_title.text=(txt("IN CAMPO / ","ON COURT / ") if intro else txt("ALLENAMENTO IN PAUSA / ","PRACTICE PAUSED / "))+exercise.title
	modal_body.text=exercise.body+"\n\n"+(pending if not pending.is_empty() else txt("Due esecuzioni riuscite completano la lezione. Puoi saltare a qualsiasi altra lezione o continuare liberamente.","Two successful attempts complete the lesson. You can move to any other lesson or continue freely."))+"\n"+txt("Camera frontale nei tutorial. Tastiera: Spazio = Croce/A, Q = Quadrato/X, E = Cerchio/B, Z/B = L2/R2; WASD/frecce = levetta sinistra.","Tutorials use the front camera. Keyboard: Space = Cross/A, Q = Square/X, E = Circle/B, Z/B = L2/R2; WASD/arrows = left stick.")
	var names=[txt("INIZIA ESERCIZIO","START DRILL") if intro else (txt("CONTINUA LIBERO","CONTINUE FREELY") if successes>=2 else txt("RIPRENDI","RESUME")),txt("RIPROVA ORA","RETRY NOW"),txt("‹ LEZIONE PRECEDENTE","‹ PREVIOUS LESSON"),txt("LEZIONE SUCCESSIVA ›","NEXT LESSON ›"),txt("CATEGORIE","CATEGORIES"),txt("MENU PRINCIPALE","MAIN MENU")]
	for i in names.size(): modal_buttons[i].text=names[i]
	modal_buttons[2].disabled=lesson_index==0
	modal_buttons[0].grab_focus()

func resume():
	if not active: return
	if successes>=2: free_practice=true
	modal.hide(); coach.show(); game.paused=false
	if not pending.is_empty() or paused_charge: prepare_attempt()
	paused_charge=false
	for action in ["action","alternate","dump"]: Input.action_release(action)
	var focused=get_viewport().gui_get_focus_owner()
	if focused: focused.release_focus()
	update_coach()

func _input(event: InputEvent):
	if menu!=null and menu.visible:
		if event.is_action_pressed("ui_cancel"):
			close_menu(); get_viewport().set_input_as_handled()
		return
	if not active: return
	var escape: bool=event is InputEventKey and event.pressed and not event.echo and event.physical_keycode==KEY_ESCAPE
	if event.is_action_pressed("start") or escape:
		if modal.visible and escape and modal_intro: open(host)
		elif modal.visible: resume()
		else: show_modal()
		get_viewport().set_input_as_handled(); return
	if modal.visible and event.is_action_pressed("ui_cancel"):
		if modal_intro: open(host)
		else: resume()
		get_viewport().set_input_as_handled(); return
	if not modal.visible and event is InputEventKey and event.pressed and not event.echo and event.physical_keycode==KEY_R:
		prepare_attempt(); get_viewport().set_input_as_handled(); return
	# Keep lesson directions consistent with their front-camera diagrams.
	if (event is InputEventJoypadButton and event.button_index==JOY_BUTTON_Y) or (event is InputEventKey and event.physical_keycode in [KEY_C,KEY_F2,KEY_F3]): get_viewport().set_input_as_handled()

func prepare_attempt():
	pending=""; pending_ok=false; performed.clear(); max_move=0; jump_members=0; jump_left=false; jump_right=false; feed_ready_at=-1; staged_hitter=-1
	game.paused=false; game.server=0 if category=="serve" else 1; game.rotations=[int(exercise.get("rotation",0)),0]
	game.clock_time=0; game.attack_serial=0; game.shot_serial=0; game.rally_serial=0
	if exercise.get("dump",false): game.rotations[0]=3
	game.scores=[0,0]; game.sets=[0,0]; game.match_finished=false; game.demo=false; game.camera_mode=0
	game.reset_rally(); game.started=true; game.input_team=0; game.set_dir=0; game.aim=Vector2(0,-1); game.block_helper_x=0
	game.point_formation.clear()
	game.receive_feedback_left=0
	game.rng.seed=60000+category_index()*1000+lesson_index*31+attempts
	for i in game.players.size():
		var p=game.players[i]; p.visible=i<6 or category in ["receive","block"]; p.velocity=Vector3.ZERO; p.acceleration=Vector3.ZERO; p.blend_left=0
		p.rotation.y=PI if i<6 else 0.0; p.apply_pose(0)
	if category=="serve": server_origin=game.players[game.server_index(0)].position
	elif category=="receive": prepare_receive()
	elif category in ["set","block"]: prepare_set_feed(category=="block")
	elif category=="attack": prepare_attack()
	began_at=game.clock_time; jump_seen=game.block_jump_log.size(); attempts+=1
	show_target(); update_coach(); game.set_camera()

func prepare_receive():
	game.possession=0; game.phase="RECEIVE"; game.phase_time=0; game.receiver=3; game.selected=3
	game.players[3].position=Vector3(0,0,5.5)
	game.incoming_kind="spike" if exercise.get("dig",false) else "serve"; game.incoming_power=.88 if exercise.get("dig",false) else .65
	game.last_touch=1; game.test_rallies=1; game.block_checked=true
	var p=game.players[3]
	var point: Vector3=p.contact_world("receive"); game.select_receive_pose(3,point); point=p.contact_world("receive")
	game.ball_pos=Vector3(.2,3.8,-1.5 if exercise.get("dig",false) else -9.8)
	game.launch(point,float(exercise.feed)); game.receive_deadline=game.clock_time+game.flight_left; game.marker.visible=true

func prepare_set_feed(opponent: bool):
	var team:=1 if opponent else 0
	game.possession=team; game.phase="CPU_SET" if opponent else "SET"; game.phase_time=0; game.setter=team*6+5; game.receiver=team*6+4
	game.touches[team]=1; game.test_rallies=1; game.pass_quality=1.0; game.set_quality=1.0; game.out_of_system=1; game.setter_action="set"
	game.set_dir=int(exercise.get("direction",0)); game.fast_set=false
	var point: Vector3=game.Tactics.world(team,1.5,.70 if exercise.get("dump",false) else 1.5)
	var p=game.players[game.setter]; p.setting_yaw=-PI/2 if team==0 else PI/2; p.rotation.y=p.setting_yaw
	game.plan_attack(game.set_dir,false)
	point.y=p.contact_local("set").y
	p.position=p.stance_for_contact("set",point); p.target=p.position; p.intent.reset(p.position)
	if not opponent and not exercise.get("dump",false) and game.planned_hitter>=0:
		var hit: Vector3=game.RallyAI.attack_contact(game,game.set_dir,game.planned_hitter,point)
		hit.y=game.players[game.planned_hitter].contact_local("attack").y
		var stance: Vector3=game.players[game.planned_hitter].stance_for_contact("attack",hit)
		game.players[game.planned_hitter].position=game.attack_run.takeoff_stance(game,game.planned_hitter,stance)+Vector3(0,0,.40)
		if exercise.get("fast",false) and game.set_dir in [0,2]:
			staged_hitter=game.planned_hitter; staged_stance=game.attack_run.takeoff_stance(game,staged_hitter,stance)
			game.players[staged_hitter].position=staged_stance
	# Let hitters open and blockers read a genuine incoming pass before the set.
	game.ball_pos=game.Tactics.world(team,-.6,5.4)+Vector3.UP*1.25; game.last_touch=team
	game.launch(point,1.55); game.selected=game.setter if team==0 else game.manual_wall.line(game)[1]
	if opponent:
		var row: Array=game.manual_wall.line(game)
		for i in row:
			game.players[i].position=Vector3(-3.4 if i==row[0] else (3.4 if i==row[2] else 0),0,.68); game.players[i].target=game.players[i].position
		feed_point=point; feed_ready_at=game.clock_time+2.0; game.airborne=false; game.flight_left=3.55

func prepare_attack():
	game.possession=0; game.receiver=4; game.set_dir=int(exercise.get("direction",0))
	game.players[4].position=Vector3(0,0,5.5); game.players[5].position=Vector3(1.65,0,2)
	game.ball_pos=game.players[4].contact_world("receive"); game.phase="RECEIVE"; game.armed=true; game.input_quality=1; game.incoming_kind="spike"; game.incoming_power=.2
	game.receive_ball()
	game.set_dir=int(exercise.get("direction",0)); game.press_action("alternate" if exercise.get("fast",false) else "action")
	game.aim=Vector2(0,-1)

func coach_attack_target() -> Vector3:
	# A predictable straight training attack. Match AI never uses this hook.
	if exercise.get("central_feed",false): return Vector3(clampf(-game.ball_pos.x*7.0/maxf(.6,absf(game.ball_pos.z)),-4.1,4.1),.105,7.0)
	if exercise.get("sealed",false): return Vector3(clampf(game.ball_pos.x*.5,-3.5,3.5),.105,7.0)
	return Vector3(clampf(game.ball_pos.x,-3.5,3.5),.105,7.0)

func practice_targets(targets: Array[Vector3]):
	# In the setter-only quick-pin drill, the coach supplies an already ready
	# hitter. Do not fail the learner's correct set because of a long approach.
	# The full running approach is retained in the separate attack category.
	if category=="set" and game.phase=="SET" and staged_hitter>=0: targets[staged_hitter]=staged_stance

func coach_seconds(point: Vector3,seconds: float) -> float:
	# The introductory centre feeds have a readable arc through raised hands.
	# The ball still uses the production ballistic solver, gravity and collision.
	return preload("res://src/winning_shot.gd").flight_seconds(game,point,seconds,3.07) if exercise.get("central_feed",false) else seconds

func before_step(_dt: float) -> bool:
	if not active: return false
	if feed_ready_at>=0:
		if game.clock_time>=feed_ready_at:
			game.launch(feed_point,1.55); feed_ready_at=-1
		else:
			game.flight_left=feed_ready_at-game.clock_time+1.55
			coach_result.text=txt("Prepara il muro · lancio tra %d s","Prepare your block · feed in %d s")%int(ceil(feed_ready_at-game.clock_time))
	if not pending.is_empty() and game.clock_time>=retry_at:
		if successes>=int(exercise.goal) and not free_practice: show_modal(); return true
		prepare_attempt(); return true
	if category in ["serve","attack"] and game.phase=="CPU_RECEIVE":
		game.phase="LOOSE"; game.flight_left=100; game.marker.hide()
	if category=="set" and game.phase=="ATTACK" and not game.armed: game.armed=true; game.input_quality=1; game.charge=.65
	if category=="serve" and game.phase=="SERVE" and not game.charging and not game.toss_active and not game.serve_adjusting: max_move=maxf(max_move,game.players[game.server_index(0)].position.distance_to(server_origin))
	if category=="block" and game.block_jump_log.size()>jump_seen:
		jump_seen=game.block_jump_log.size(); jump_members=0
		for index in game.manual_wall.jumped:
			if game.block_jumps.has(index): jump_members+=1
		jump_left=game.wall_strength("block_left")>.35; jump_right=game.wall_strength("block_right")>.35
	if pending.is_empty() and game.clock_time-began_at>(25.0 if category=="serve" else 12.0): result(false,txt("Prova terminata. Premi il comando indicato nel momento dell'azione.","Attempt ended. Use the indicated control as the action arrives."))
	return false

func on_event(event: Dictionary):
	if not active or not pending.is_empty(): return
	var kind: String=event.kind
	if category=="serve" and kind in ["float_serve","power_serve"]: performed={"power":game.last_power,"style":game.serve_type}
	elif category=="attack" and kind in ["spike","soft"] and game.last_touch==0: performed={"power":game.last_power,"tip":game.attack_tip}
	elif category=="receive" and kind in ["reception","dig"] and event.get("receiver",-1)<6:
		var quality: float=event.get("quality",0)
		var okay: bool=quality>=float(exercise.quality) and (not exercise.get("late",false) or game.receive_offset<0)
		var timing_text: String=preload("res://src/shot_variation.gd").reception_label(game.receive_offset)
		if TranslationServer.get_locale().begins_with("en"): timing_text={"MOLTO IN ANTICIPO":"VERY EARLY","IN ANTICIPO":"EARLY","LEGGERMENTE IN ANTICIPO":"SLIGHTLY EARLY","PERFETTA":"PERFECT","LEGGERMENTE IN RITARDO":"SLIGHTLY LATE","MOLTO IN RITARDO":"VERY LATE"}.get(timing_text,timing_text)
		result(okay,(txt("Qualità %d%% · ","Quality %d%% · ")%roundi(quality*100))+timing_text)
	elif category=="set" and kind in ["high_set","quick_set","setter_dump"] and game.last_touch==0:
		var okay: bool=kind=="setter_dump" if exercise.get("dump",false) else (kind!="setter_dump" and int(event.get("direction",-1))==int(exercise.direction) and game.fast_set==bool(exercise.fast))
		result(okay,txt("Alzata corretta: attaccante e variante richiesti.","Correct set: requested hitter and delivery.") if okay else txt("Contatto riuscito, ma scegli la direzione e il tasto della lezione prima di alzare.","Contact made, but select this lesson's direction and button before setting."))
	elif category=="block" and kind in ["stuff_block","block_touch","block_tool"] and event.get("blocking_team",-1)==0:
		var okay: bool=(not exercise.get("left",false) or jump_left) and (not exercise.get("right",false) or jump_right) and jump_members>=int(exercise.get("members",1)) and (not exercise.get("sealed",false) or kind=="stuff_block")
		result(okay,txt("Muro pieno!","Sealed block!") if okay and kind=="stuff_block" else (txt("Tocco di muro riuscito.","Successful block touch.") if okay else txt("Hai toccato: controlla grilletti, numero di muratori e chiusura richiesti.","You touched it: check the requested triggers, blockers and seal.")))
	elif kind=="missed_contact" and ((category=="receive" and event.get("phase","")=="RECEIVE") or (category=="set" and event.get("phase","")=="SET") or (category=="attack" and event.get("phase","")=="ATTACK")):
		result(false,txt("Contatto mancato. ","Contact missed. ")+(txt("Premi il tasto: non è stato dato il comando.","Press the action button: no contact was commanded.") if not event.get("armed",false) else txt("Riprova seguendo il tempo e il comando indicati.","Try again with the indicated timing and control.")))

func on_point(team: int,reason: String):
	if pending.is_empty():
		if category in ["serve","attack"]:
			var power: float=performed.get("power",game.serve_power if category=="serve" else game.last_power)
			var okay: bool=not performed.is_empty() and power>=float(exercise.get("min",0)) and power<=float(exercise.get("max",1.0)) and team==0 and reason=="PALLA A TERRA"
			if category=="serve":
				if exercise.has("style"): okay=okay and performed.get("style",-1)==int(exercise.style)
				okay=okay and max_move>=float(exercise.get("move",0))
				if exercise.get("experiment",false): okay=power>=float(exercise.min) and power<=float(exercise.max)
			elif category=="attack": okay=okay and performed.get("tip",false)==bool(exercise.get("tip",false))
			if exercise.has("zone"):
				var where:=Vector2(game.ball_pos.x,game.ball_pos.z)
				okay=okay and where.distance_to(exercise.zone)<=float(exercise.radius)
			var report:=txt("Carica: %d%%. ","Charge: %d%%. ")%roundi(power*100)
			if okay: report+=txt("Obiettivo raggiunto!","Target achieved!")
			elif power<float(exercise.get("min",0)) or power>float(exercise.get("max",1.0)): report+=txt("Rilascia nella fascia richiesta.","Release in the requested power band.")
			elif category=="serve" and max_move<float(exercise.get("move",0)): report+=txt("Spostati almeno 80 cm PRIMA della carica.","Move at least 80 cm BEFORE charging.")
			else: report+=txt("Controlla tasto, bersaglio e caduta in campo.","Check the button, target and in-court landing.")
			result(okay,report)
		else: result(false,txt("Palla terminata: leggi la traiettoria e riprova.","Ball ended: read the flight and try again."))
	game.point_reason=reason; game.phase="POINT"; game.phase_time=0; game.airborne=true; game.ball_pos.y=maxf(.105,game.ball_pos.y); game.marker.hide()

func result(okay: bool,message: String):
	if not pending.is_empty(): return
	pending=message; pending_ok=okay; retry_at=game.clock_time+1.7
	if okay:
		successes+=1
		var key:=category+":"+str(exercise.id)
		progress[key]=maxi(int(progress.get(key,0)),mini(successes,int(exercise.goal))); save_progress()
	update_coach()

func load_progress():
	var file=ConfigFile.new()
	if file.load("user://tutorial-progress.cfg")!=OK: return
	for key in file.get_section_keys("lessons"): progress[key]=clampi(int(file.get_value("lessons",key,0)),0,2)

func save_progress():
	var file=ConfigFile.new()
	for key in progress: file.set_value("lessons",key,progress[key])
	file.save("user://tutorial-progress.cfg")

func show_target():
	if is_instance_valid(target): target.queue_free()
	target=Node3D.new(); game.add_child(target)
	var point:=Vector2(0,-6.0); var radius:=2.3
	if exercise.has("zone"): point=exercise.zone; radius=float(exercise.radius)
	elif category=="receive": point=Vector2(1.2,1.5); radius=1.0
	elif category=="set":
		var index: int=game.Tactics.attacker_for(game,0,int(exercise.get("direction",0)),game.setter)
		if index>=0:
			var contact: Vector3=game.RallyAI.attack_contact(game,int(exercise.get("direction",0)),index,game.flight_target); point=Vector2(contact.x,contact.z)
		radius=.85
		if exercise.get("dump",false): point=Vector2(1.5,-2.3); radius=1.1
	elif category=="block":
		point=Vector2(0,.68); radius=.7
		if not exercise.get("central_feed",false) and game.planned_hitter>=0:
			var contact: Vector3=game.RallyAI.attack_contact(game,int(exercise.direction),game.planned_hitter,game.flight_target)
			point.x=contact.x*.73
	target.position=Vector3(point.x,.025,point.y)
	var mesh=MeshInstance3D.new(); var circle=CylinderMesh.new(); circle.top_radius=radius; circle.bottom_radius=radius; circle.height=.012; circle.radial_segments=48; mesh.mesh=circle
	var material=StandardMaterial3D.new(); material.albedo_color=Color(.20,.87,.79,.24); material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA; material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED; mesh.material_override=material; target.add_child(mesh)
	var ring=MeshInstance3D.new(); var torus=TorusMesh.new(); torus.inner_radius=radius-.035; torus.outer_radius=radius+.035; torus.rings=48; torus.ring_segments=8; ring.mesh=torus
	var gold=StandardMaterial3D.new(); gold.albedo_color=Color("f3d087"); gold.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED; ring.material_override=gold; target.add_child(ring)
	target_label=Label3D.new(); target_label.text=txt("BERSAGLIO","TARGET"); target_label.font_size=38; target_label.pixel_size=.008; target_label.billboard=BaseMaterial3D.BILLBOARD_ENABLED; target_label.position=Vector3(0,.22,0); target_label.modulate=Color("fff1cc"); target.add_child(target_label)
	if category=="receive": target_label.text=txt("ZONA D'ALZATA","SETTING AREA")
	if category=="set": target_label.text=txt("DESTINAZIONE","DESTINATION")
	if category=="block": target_label.text=txt("CHIUSURA","BLOCK LANE")
	if category in ["serve","attack"] and not exercise.has("zone"): target.hide()
