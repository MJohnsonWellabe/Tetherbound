extends "res://tests/smoke_stronghold_battle_camera.gd"

## F04 evidence for the Stronghold gauntlet camera (OP23-02) after the
## nearest-wall distance cap was removed: runs smoke_stronghold_battle_camera.gd
## unchanged -- every assertion, same fight, same room -- and additionally saves
## the ordinary neutral fight frame and one frame after the orbit sampling.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 \
##     --resolution 1280x720 --script tests/capture_hall_gauntlet_camera.gd -- --capture-dir=<abs dir>

var _capture_dir := ""


func _init() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="):
			_capture_dir = arg.trim_prefix("--capture-dir=")
			DirAccess.make_dir_recursive_absolute(_capture_dir)
	super()


func _prove_dynamic_framing_uses_spring_collision() -> void:
	await _save_frame("gauntlet_fight_neutral")
	await super()
	for i in 90:
		await physics_frame
	await _save_frame("gauntlet_fight_after_orbit")


func _save_frame(label: String) -> void:
	if _capture_dir.is_empty():
		return
	await RenderingServer.frame_post_draw
	var image := root.get_viewport().get_texture().get_image()
	if image.save_png(_capture_dir.path_join("%s.png" % label)) != OK:
		_fail("capture: could not save %s" % label)
