extends SceneTree
const Catalog=preload("res://src/online_catalog108.gd")
const Connections=preload("res://src/online_connections108.gd")
const Code=preload("res://src/room_code.gd")
var errors: Array=[]
var checks:=0
func check(value: bool,message: String):
	checks+=1
	if not value:errors.append(message)
func _initialize():call_deferred("run")
func run():
	assert("online108" in OS.get_environment("APPDATA"))
	var db=load("res://src/league.gd").new();var before:=Catalog.digest({"teams":db.teams,"overrides":db.overrides})
	var host:=Catalog.new();var payload:=host.capture(db);var stamp:=Catalog.digest(payload)
	var guest:=Catalog.new();check(guest.install(payload,stamp),"verified host snapshot installs")
	check(not Catalog.new().install(payload,"wrong"),"mismatched host digest rejected")
	check(Catalog.digest(guest.payload())==stamp,"host and guest have identical sorted snapshot hashes")
	for team in host.teams:
		var squad:=host.lineup(team)
		check(squad.size()==7,"host saved/default formation "+str(team.id))
		var ids: Array=squad.map(func(p):return p.id)
		var fake: Array=squad.duplicate(true)
		for p in fake:p.name="GUEST";p.ratings.schiacciata=1;p.role="libero";p.dominant_hand="left"
		var canonical:=host.canonical({"club":team.id,"roster":fake,"bench":[]})
		check(canonical.roster==squad,"guest attributes replaced with complete host player identities")
		check(canonical.bench.size()==team.roster.size()-7,"bench comes from host, cannot be omitted by guest")
		check(guest.lineup(guest.teams.filter(func(t):return t.id==team.id)[0])==squad,"guest default formation matches host")
		fake[0].id="invented";check(host.canonical({"club":team.id,"roster":fake}).is_empty(),"unknown guest player ID rejected")
	check(Catalog.digest({"teams":db.teams,"overrides":db.overrides})==before,"catalogue never mutates source database")
	var profile:=Connections.new();var id:=profile.host_id();var reloaded:=Connections.new()
	profile.recent=[];profile.save()
	check(reloaded.host_id()==id,"host invite identity survives a new process/profile load")
	var a:=Code.encode("127.0.0.1",26761,id)
	check(Code.encode("127.0.0.1",26761,reloaded.host_id())==a,"same endpoint generates same full invite")
	profile.remember(a,"Amico");profile.remember(a,"Amico")
	check(profile.recent.size()==1,"successful invites deduplicated")
	profile.remember("not a code");check(profile.recent.size()==1,"invalid code not remembered")
	for i in 10:profile.remember(Code.encode("127.0.0.1",26761,100+i),"Host "+str(i))
	check(profile.recent.size()==8,"history is bounded")
	var reopened:=Connections.new()
	check(reopened.recent.size()==8 and reopened.recent[0].label=="Host 9","recent rooms persist in newest-first order")
	check(Code.decode(reopened.recent[0].code).room==109,"history retains valid reconnect endpoint")
	FileAccess.open("res://docs/online108-catalog-history.json",FileAccess.WRITE).store_string(JSON.stringify({"pass":errors.is_empty(),"checks":checks,"errors":errors,"catalog_hash":stamp},"  "))
	print("CATALOG108 ","PASS" if errors.is_empty() else "FAIL"," checks=",checks," errors=",errors);quit(0 if errors.is_empty() else 1)
