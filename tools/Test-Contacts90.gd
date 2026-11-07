extends "res://tools/Test-OnlineContacts65.gd"
var previous_state90:=""
var events90: Array=[]
var seen90: Dictionary={}
func _process(dt: float) -> bool:
	var result: bool=super._process(dt)
	if g!=null and role=="host" and net.playing:
		var state: String=str([g.phase,g.armed,g.setter,g.rally_serial])
		if state!=previous_state90:
			previous_state90=state
			events90.append({"state":state,"time":g.clock_time,"ball":g.ball_pos,"target":g.flight_target,"contacts":g.contact_log.size()})
		for event in g.rally_events:
			var key: String=str(event)
			if not seen90.has(key):
				seen90[key]=true
				if event.kind in ["contact_rejected","online_miss"]:events90.append(event.duplicate(true))
		if age>34:
			FileAccess.open("res://docs/stature90-online-contact-events.json",FileAccess.WRITE).store_string(JSON.stringify(events90,"  "))
	return result
