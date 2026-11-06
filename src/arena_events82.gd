extends RefCounted
static func point_kind(game,team: int) -> String:
	var block: Dictionary=game.get_meta("led_block82",{})
	if block.get("team",-1)==team and block.get("rally",-1)==game.rally_serial:return "MONSTER BLOCK"
	var manager=game.match_management
	if manager.active:
		if manager.served_by>=0 and int(manager.served_by/6)==team and manager.last_attack.is_empty() and manager.last_block.is_empty():return "ACE"
	elif game.incoming_kind=="serve" and game.last_touch==team:return "ACE"
	return ""
static func show(game,kind: String,team: int):
	if kind.is_empty() or team!=game.home_team:return
	game.arena_visuals.sponsors.celebrate(kind,team,game)
	if game.network_match() and game.online_session.authority() and game.online_session.guest!=0:
		game.online_session.led_notice.rpc_id(game.online_session.guest,kind,team)
