extends "res://tools/Benchmark-Fluidity84.gd"
## Fixed-clock recording only; NEVER use these frame times as performance data.
var captured:=0
func run():
	super.run();Engine.max_fps=0
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.runtime/fluidity84-frames"))
func draw_sample():
	if game==null:return
	var screenshot:=root.get_texture().get_image()
	screenshot.save_jpg("res://.runtime/fluidity84-frames/%05d.jpg"%captured,.9)
	if captured==150:screenshot.save_png("res://docs/fluidity84-match.png")
	captured+=1
	if captured>=420:print("FLUIDITY84 CAPTURE PASS");quit()
