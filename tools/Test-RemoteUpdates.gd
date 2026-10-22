extends SceneTree

var client
var finished := false

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	client=load("res://src/update_client.gd").new()
	root.add_child(client)
	client.versions_loaded.connect(verify_versions)
	client.changed.connect(func(message): print("REMOTE UPDATE STATUS: ",message))
	client.check()
	await create_timer(45.0).timeout
	if not finished:
		push_error("Remote update discovery timed out or failed")
		quit(1)

func verify_versions(versions: Array) -> void:
	for entry in versions:
		if entry.get("tag_name","")!="v0.19.0": continue
		var asset=client.package_asset(entry)
		if asset.get("digest","")!="sha256:8fdafce1a024923679636117ada39ec044fdf0c42df9dd45d8d45db27dafc934":
			push_error("Published asset checksum differs from validated Windows package")
			quit(1)
			return
		finished=true
		print("REMOTE UPDATES PASS: live unauthenticated discovery / v0.19.0 / verified GitHub asset digest / ",versions.size()," release(s)")
		quit()
		return
	push_error("Expected first release missing")
	quit(1)
