extends RefCounted
## A separate, deterministic cosmetic RNG. Never consumes the match RNG.
const WIN=["clap","sign","point","nod","open","turn"]
const LOSS=["nod","open","turn"]
static func shuffle(items: Array,rng: RandomNumberGenerator) -> Array:
	var copy=items.duplicate()
	for i in range(copy.size()-1,0,-1):
		var j=rng.randi_range(0,i);var item=copy[i];copy[i]=copy[j];copy[j]=item
	return copy
static func plan(entries: Array,team: int,won: bool,key: String,previous: Dictionary) -> Dictionary:
	var rng=RandomNumberGenerator.new();rng.seed=hash("bench71/"+key+"/"+str(team))
	var seats: Array=shuffle(entries.filter(func(e):return e.actor.visible and not e.coach),rng)
	var families: Array=shuffle(WIN if won else LOSS,rng)
	var result: Dictionary={}
	var coach: Array=entries.filter(func(e):return e.actor.visible and e.coach)
	if won and not coach.is_empty() and rng.randf()<.48:
		var family: String="sign" if rng.randf()<.55 else "point"
		families.erase(family)
		result[8]={"family":family,"clip":"coach_"+family,"delay":rng.randf_range(.25,1.05),"speed":rng.randf_range(1.02,1.14)}
	var count:=mini(seats.size(),rng.randi_range(2,4) if won else rng.randi_range(0,1))
	for i in count:
		var seat=seats[i];var slot: int=seat.slot
		# A player cannot repeat his own previous gesture on the following point.
		var options: Array=families.filter(func(f):return f!=previous.get(slot,""))
		if options.is_empty():continue
		var family: String=options[0];families.erase(family)
		var suffix: String="l" if slot%2==0 else "r"
		var clip: String="bench_"+family+"_"+suffix
		if family=="clap" and slot in [6,7] and rng.randf()<.35:clip="bench_stand_"+suffix
		result[slot]={"family":family,"clip":clip,"delay":rng.randf_range(.15,1.35),"speed":rng.randf_range(1.04,1.20)}
	return result
