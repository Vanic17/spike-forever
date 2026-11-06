extends RefCounted
## Session-local identifiers prevent two copies of a club from sharing the
## management identity/fatigue ledger. Never write these IDs to the database.
static func players(roster: Array,side: int) -> Array:
	var result: Array=[]
	for original in roster:
		var person: Dictionary=original.duplicate(true)
		person.database_id=str(original.get("database_id",original.id))
		person.id="online%d|%s"%[side,person.database_id]
		result.append(person)
	return result
