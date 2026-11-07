extends SceneTree

func _initialize():call_deferred("run")
func run():
	var source:=AudioStreamWAV.load_from_file("res://assets/audio/crowd.wav")
	assert(source!=null and source.stereo and source.mix_rate==48000)
	assert(abs(source.get_length()-90.320625)<.001)
	var imported=load("res://assets/audio/crowd.wav")
	assert(imported is AudioStreamWAV and imported.stereo and imported.mix_rate==48000)
	assert(abs(imported.get_length()-source.get_length())<.001)
	var legacy:=AudioStreamOggVorbis.load_from_file("res://assets/audio/crowd.ogg")
	assert(legacy!=null)
	# Every sidecar must still refer to an existing source and generated resource.
	var paths: Array[String]=[]
	walk("res://assets",paths)
	var invalid: Array[String]=[]
	for path in paths:
		var cfg:=ConfigFile.new()
		if cfg.load(path)!=OK:invalid.append(path);continue
		if not FileAccess.file_exists(cfg.get_value("deps","source_file","")):invalid.append(path);continue
		if not ResourceLoader.exists(cfg.get_value("deps","source_file","")):invalid.append(path);continue
		for destination in cfg.get_value("deps","dest_files",PackedStringArray()):
			if not FileAccess.file_exists(destination):invalid.append(destination)
	assert(invalid.is_empty(),str(invalid))
	var result={"pass":true,"crowd_channels":2,"rate":source.mix_rate,"duration":source.get_length(),"imported_length":imported.get_length(),"sidecars":paths.size(),"invalid_resources":invalid,"runtime_ogg_preserved":true}
	FileAccess.open("res://docs/audio85-import-tests.json",FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
	print("IMPORT85 PASS ",JSON.stringify(result));quit()
func walk(folder: String,result: Array[String]):
	if FileAccess.file_exists(folder.path_join(".gdignore")):return
	for filename in DirAccess.get_files_at(folder):
		if filename.ends_with(".import"):result.append(folder.path_join(filename))
	for child in DirAccess.get_directories_at(folder):walk(folder.path_join(child),result)
