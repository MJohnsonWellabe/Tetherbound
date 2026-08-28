extends SceneTree

## The capture reticle's two aim states, side by side.
##
##   xvfb-run -a -s "-screen 0 1920x1080x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1920x1080 \
##     --script tools/_probe_capture_reticle_states.gd -- --out=shots/catch_aim
##
## Before this pass there was only one state. `catch_chance_now()` fed the ring
## the DEAD-CENTRE chance whether or not the player was on the creature, so the
## left and centre panels below were the same picture with the same number --
## and in a real fight (see `smoke_catching.gd`'s `catch launch:` log) the
## right-hand case was every throw.

const RETICLE := preload("res://scripts/ui/capture_reticle.gd")

var _out_dir := "res://shots/catch_aim"


func _init() -> void:
	_run()


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		print("headless has no renderer; run under xvfb-run")
		quit(1)
		return
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out_dir = arg.substr(6)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_out_dir))
	for i in 4:
		await process_frame

	var world := Node3D.new()
	world.name = "ReticleWorld"
	root.add_child(world)
	current_scene = world
	var layer := CanvasLayer.new()
	world.add_child(layer)
	var bg := ColorRect.new()
	bg.color = Color("#3d6a86")  ## the sky the survey frames sit against
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(bg)

	# Three panels: a dead-centre lock, a clipped-but-landing lock, and an aim
	# that is not on the creature at all -- which is the case the old ring drew
	# identically to the first.
	var panels: Array = [
		{"x": 320.0, "chance": 0.731, "locked": true,  "caption": "ON TARGET, dead centre"},
		{"x": 960.0, "chance": 0.403, "locked": true,  "caption": "ON TARGET, clipping the edge"},
		{"x": 1600.0, "chance": 0.403, "locked": false, "caption": "NOT on the creature"},
	]
	var font := ThemeDB.fallback_font
	for p: Dictionary in panels:
		var r: Control = RETICLE.new()
		r.set_anchors_preset(Control.PRESET_FULL_RECT)
		layer.add_child(r)
		r.call("update_target", Vector2(float(p["x"]), 420.0), float(p["chance"]), true, bool(p["locked"]))
		var label := Label.new()
		label.text = str(p["caption"])
		label.add_theme_font_size_override("font_size", 26)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.position = Vector2(float(p["x"]) - 300.0, 640.0)
		label.size = Vector2(600.0, 40.0)
		layer.add_child(label)

	var note := Label.new()
	note.text = "Before this pass all three drew the LEFT picture: catch_chance_now() passed offset 0.0 unconditionally,\nso the ring showed the dead-centre number with no way to tell whether the player was on the creature."
	note.add_theme_font_size_override("font_size", 24)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.position = Vector2(160.0, 800.0)
	note.size = Vector2(1600.0, 90.0)
	layer.add_child(note)

	for i in 20:
		await process_frame
	var path := "%s/reticle_states.png" % _out_dir
	get_root().get_texture().get_image().save_png(ProjectSettings.globalize_path(path))
	print("wrote %s" % path)
	quit(0)
