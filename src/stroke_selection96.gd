extends RefCounted
static func short_diagonal(game) -> bool:
	return game.aim.y>.3 and absf(game.aim.x)>.3 and absf(game.players[game.hitter].position.x)>1.3 and game.aim.x*game.players[game.hitter].position.x<0
static func update(game):
	if game.phase not in ["ATTACK","CPU_ATTACK"] or not game.human_team(game.possession) or game.hitter_action!="attack":return
	var p=game.players[game.hitter]
	if game.attack_tip:p.wrist_tip_variant="attack_shorttip96" if game.aim.y>.3 else "attack_wrist94"
	elif short_diagonal(game):p.wrist_tip_variant="attack_cut96"
	elif p.wrist_tip_variant=="attack_cut96":p.wrist_tip_variant=""
