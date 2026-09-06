extends SceneTree

## QUICK TOUR -- title screen. No dedicated title-screen capture tool exists
## in this repo; the only place the title screen is shot at all is inside
## tools/_capture_ui_survey.gd::_shoot_title_screen(), lifted here verbatim
## (load the scene, add it, settle 12 frames, shutter) because pulling in
## that whole 300+-frame survey just for one frame would blow this tool's
## budget on its own. Shared between both biome passes -- the title screen
## is not biome-specific -- so tools/owner/quick_tour.ps1 runs this once.
##
##   godot --path . --rendering-driver opengl3 --resolution 1280x800 \
##     --script tools/_capture_quick_tour_title.gd -- --out=res://shots_quick_tour/title.png

const TITLE_SCENE := "res://scenes/ui/title_screen.tscn"
const DEFAULT_OUT := "res://shots_quick_tour/title.png"


func _init() -> void:
	_run()


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		print("headless has no renderer; run this under xvfb-run or a real GPU")
		quit(1)
		return
	var out_path := DEFAULT_OUT
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out_path = a.substr("--out=".length())
			if not out_path.begins_with("res://"):
				out_path = "res://" + out_path

	var packed: PackedScene = load(TITLE_SCENE)
	if packed == null:
		push_error("could not load %s" % TITLE_SCENE)
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_path.get_base_dir()))
	var screen: Control = packed.instantiate() as Control
	root.add_child(screen)
	for i in 12:
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null:
		push_error("viewport returned no image")
		quit(1)
		return
	var err := image.save_png(out_path)
	if err != OK:
		push_error("save_png failed (%d)" % err)
		quit(1)
		return
	print("  title -> %s" % out_path)
	quit(0)
