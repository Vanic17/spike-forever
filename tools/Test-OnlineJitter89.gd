extends "res://tools/Test-OnlineContacts65.gd"
## Reuse the actual two-human ENet match fixture. Polling in bursts adds
## controlled transport jitter on both peers without production test hooks.
var poll_elapsed89:=0.0
var poll_interval89:=.035
var poll_index89:=0
func _initialize():
	multiplayer_poll=false
	super._initialize()
func _process(dt: float):
	poll_elapsed89+=dt
	if poll_elapsed89>=poll_interval89:
		root.get_multiplayer().poll();poll_elapsed89=0
		poll_index89+=1;poll_interval89=[.020,.065,.035,.090][poll_index89%4]
	return super._process(dt)
